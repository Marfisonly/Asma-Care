import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'asmainfo_screen.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool _isConnected = false;

  double temperature = 0.0;
  double humidity = 0.0;
  double airPressure = 0.0;

  String _buffer = '';
  String asthmaSeverity = '';
  String medicationDosage = '';

  // List untuk menyimpan data tekanan dan timestamp selama 1 menit
  List<Map<String, dynamic>> _pressureTimestamps = [];

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      bool semuaDiizinkan = statuses.values.every((status) => status.isGranted);

      if (!semuaDiizinkan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua izin Bluetooth dan lokasi diperlukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    _connectToBluetooth();
  }

  void _connectToBluetooth() async {
    if (_connection != null && _connection!.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sudah terhubung dengan perangkat'), backgroundColor: Colors.green),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada perangkat yang terpasang'), backgroundColor: Colors.orange),
        );
      } else {
        BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Pilih Perangkat'),
            children: devices.map((device) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, device),
                child: Text(device.name ?? device.address),
              );
            }).toList(),
          ),
        );

        if (selectedDevice != null) {
          BluetoothConnection connection = await BluetoothConnection.toAddress(selectedDevice.address)
              .timeout(const Duration(seconds: 10));

          setState(() {
            _connectedDevice = selectedDevice;
            _connection = connection;
            _isConnected = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terhubung ke ${selectedDevice.name}'),
            backgroundColor: Colors.green,
          ));

          if (connection.input != null) {
            connection.input!.listen((data) {
              String incomingData = String.fromCharCodes(data);
              _buffer += incomingData;

              if (_buffer.contains('\n')) {
                List<String> lines = _buffer.split('\n');
                for (var line in lines) {
                  _parseSensorData(line.trim());
                }
                _buffer = '';
              }
            }).onDone(() {
              setState(() {
                _isConnected = false;
                _connectedDevice = null;
              });
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Input dari perangkat tidak tersedia'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghubungkan: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _disconnectBluetooth() async {
    if (_connection != null) {
      await _connection!.close();
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _connection = null;

        // Reset data sensor dan tingkat keparahan asma
        temperature = 0.0;
        humidity = 0.0;
        airPressure = 0.0;
        asthmaSeverity = '';
        _pressureTimestamps.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth terputus, data direset'), backgroundColor: Colors.red),
      );
    }
  }

  void _parseSensorData(String data) {
    try {
      List<String> parts = data.split('|');
      double? temp, humid, pressure;

      for (String part in parts) {
        if (part.contains('Suhu')) {
          temp = double.parse(part.split(':')[1].replaceAll('C', '').trim());
        } else if (part.contains('Kelembapan')) {
          humid = double.parse(part.split(':')[1].replaceAll('%', '').trim());
        } else if (part.contains('Tekanan')) {
          pressure = double.parse(part.split(':')[1].replaceAll('hPa', '').trim());
        }
      }

      if (temp != null && humid != null && pressure != null) {
        setState(() {
          temperature = temp!;
          humidity = humid!;
          airPressure = pressure!;
        });

        // Tambahkan tekanan dan waktu ke dalam list
        _pressureTimestamps.add({
          'timestamp': DateTime.now(),
          'pressure': pressure
        });

        // Bersihkan data lebih dari 60 detik
        _pressureTimestamps = _pressureTimestamps.where((entry) {
          return DateTime.now().difference(entry['timestamp']).inSeconds <= 60;
        }).toList();

        // Hitung jumlah tekanan >= 1011
        int jumlahTekanan1011 = _pressureTimestamps
            .where((entry) => entry['pressure'] >= 1011.0)
            .length;

        sendDataToServer(temp, humid, pressure);
        _calculateAsthmaSeverity(temp, humid, jumlahTekanan1011);
      }
    } catch (e) {
      debugPrint('Kesalahan parsing: $e');
    }
  }

 String estimasiTingkatAsma({
  required double suhu,
  required double kelembapan,
  required int jumlahTekanan1011,
}) {
  // Logika untuk kelembapan 80%
  if (kelembapan == 80) {
    if (suhu > 36.0 && jumlahTekanan1011 > 30) {
      return "Asma Berat";
    } else if ((suhu >= 34.0 && suhu <= 36.0) &&
        (jumlahTekanan1011 >= 21 && jumlahTekanan1011 <= 30)) {
      return "Asma Sedang";
    } else if (suhu < 34.0 && (jumlahTekanan1011 >= 21 && jumlahTekanan1011 <= 30)) {
      return "Asma Ringan";
    }
  }

  // Jika jumlah tekanan sedang (tidak kelembapan 80)
  if (jumlahTekanan1011 >= 12 && jumlahTekanan1011 <= 20) {
    return "Tidak menderita asma";
  }

  // Penanganan fallback agar tidak menampilkan pesan tidak valid
  if (jumlahTekanan1011 > 30) {
    return "Asma Berat";
  } else if (jumlahTekanan1011 >= 21) {
    return "Asma Sedang";
  } else if (jumlahTekanan1011 >= 12) {
    return "Asma Ringan";
  } else {
    return "Tidak menderita asma";
  }
}


  void _calculateAsthmaSeverity(double temp, double humid, int jumlahTekanan1011) {
    setState(() {
      asthmaSeverity = estimasiTingkatAsma(
        suhu: temp,
        kelembapan: humid,
        jumlahTekanan1011: jumlahTekanan1011,
      );
    });
  }

  Future<void> sendDataToServer(double temp, double humid, double pressure) async {
    final url = Uri.parse('http://192.168.0.142/asmacare_api/save_data.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'temperature': temp.toString(),
          'humidity': humid.toString(),
          'air_pressure': pressure.toString(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Data berhasil dikirim ke server');
      } else {
        debugPrint('Gagal mengirim data: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Kesalahan saat mengirim ke server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.health_and_safety, color: Colors.blue, size: 40),
            SizedBox(width: 10),
            Text('AsmaCare',
                style: TextStyle(color: Colors.blue, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF90CAF9), Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${widget.username} 👋',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Asma terkendali, hidup lebih berarti',
                            style: TextStyle(fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Data Sensor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildSensorCard(icon: Icons.thermostat, label: 'Suhu', value: '$temperature °C', color: Colors.orange),
                const SizedBox(height: 20),
                _buildSensorCard(icon: Icons.water_drop, label: 'Kelembapan', value: '$humidity %', color: Colors.blue),
                const SizedBox(height: 20),
                _buildSensorCard(icon: Icons.air, label: 'Tekanan Udara', value: '$airPressure hPa', color: Colors.green),
                const SizedBox(height: 20),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: _getAsthmaSeverityColor(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tingkat Keparahan Asma',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          asthmaSeverity,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isConnected ? _disconnectBluetooth : _requestPermissions,
                  child: Text(_isConnected ? 'Putuskan Bluetooth' : 'Hubungkan Bluetooth'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AsmaInfoScreen(),
                      ),
                    );
                  },
                  child: const Text('Informasi Asma'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAsthmaSeverityColor() {
    switch (asthmaSeverity) {
      case 'Asma Berat':
        return Colors.red;
      case 'Asma Sedang':
        return Colors.orange;
      case 'Asma Ringan':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
