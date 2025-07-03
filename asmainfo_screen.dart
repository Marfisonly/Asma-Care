import 'package:flutter/material.dart';

class AsmaInfoScreen extends StatelessWidget {
  const AsmaInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Asma'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF90CAF9), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(
                  title: 'Apa itu Asma?',
                  content:
                      'Asma adalah kondisi kronis yang memengaruhi saluran napas, menyebabkan sesak napas, batuk, dan dada terasa berat. Gejalanya bisa dipicu oleh udara dingin, debu, olahraga, atau alergi.',
                  icon: Icons.info,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Dosis Obat untuk Asma Ringan',
                  content:
                      '• Salbutamol (Albuterol): 2.5 mg melalui nebulizer setiap 4-6 jam sesuai kebutuhan.\n• Budesonide: 0.25 mg – 0.5 mg inhalasi, dua kali sehari.\n• Fluticasone: 100 mcg – 250 mcg inhalasi, dua kali sehari.',
                  icon: Icons.medical_services,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Dosis Obat untuk Asma Sedang',
                  content:
                      '• Salbutamol (Albuterol): 2.5 mg – 5 mg melalui nebulizer setiap 4-6 jam sesuai kebutuhan.\n• Budesonide: 0.5 mg – 1 mg inhalasi, dua kali sehari.\n• Fluticasone: 250 mcg – 500 mcg inhalasi, dua kali sehari.',
                  icon: Icons.medical_services_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Dosis Obat untuk Asma Berat',
                  content:
                      '• Salbutamol (Albuterol): 2.5 – 5 mg melalui nebulizer setiap 20 menit selama 1 jam dan setiap 1-4 jam sesuai kebutuhan. Maksimum hingga 10-15 mg/jam.\n• Budesonide: 1 – 2 mg inhalasi, dua kali sehari.\n• Fluticasone: 500 – 1000 mcg dua kali sehari, bisa mencapai 2000 mcg/hari dalam kondisi berat.\n• Kombinasi: Ipratropium Bromide 0.5 mg + Salbutamol 2.5 mg melalui nebulizer selama 20 menit setiap 1-4 jam sesuai kebutuhan.',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(content, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
