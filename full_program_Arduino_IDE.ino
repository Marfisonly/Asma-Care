#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_SHT31.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
#include "BluetoothSerial.h"

const char* ssid = "POCO"; //tanpa spasi
const char* password = "123456789";
const char* serverName = "http://192.168.167.227/insert.php"; 

Adafruit_SHT31 sht31 = Adafruit_SHT31();
Adafruit_BMP280 bmp;
BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32-AsmaMonitor");

  WiFi.begin(ssid, password);
  Serial.print("Menghubungkan ke WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi terhubung!");

  Wire.begin();
  delay(100);
  if (!sht31.begin(0x44)) {
    Serial.println("Gagal mendeteksi sensor SHT31!");
    while (1);
  }
  if (!bmp.begin(0x76)) {
    Serial.println("Sensor BMP280 tidak terdeteksi!");
    while (1);
  }
  delay(1000); // Tambahkan delay agar sensor stabil sebelum digunakan

  bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
                  Adafruit_BMP280::SAMPLING_X16,
                  Adafruit_BMP280::SAMPLING_X16,
                  Adafruit_BMP280::FILTER_X16,
                  Adafruit_BMP280::STANDBY_MS_500);

  Serial.println("Sistem siap: Bluetooth dan WiFi aktif.");
}

void loop() {
  float suhu = sht31.readTemperature();
  float kelembapan = sht31.readHumidity();
  float tekanan = bmp.readPressure() / 100.0;

  String data = "Suhu:" + String(suhu, 2) + "C|"
              + "Kelembapan:" + String(kelembapan, 2) + "%|"
              + "Tekanan:" + String(tekanan, 2) + "hPa";

  // 1. Kirim ke Bluetooth (Flutter)
  SerialBT.println(data);

  // 2. Kirim ke Database (XAMPP via WiFi)
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String url = serverName;
    url += "?suhu=" + String(suhu, 2);  
    url += "&kelembapan=" + String(kelembapan, 2);
    url += "&tekanan=" + String(tekanan, 2);

    http.begin(url);
    int response = http.GET();
    if (response > 0) {
      Serial.println("Kirim ke server: " + http.getString());
    } else {
      Serial.println("Gagal kirim ke server, kode: " + String(response));
    }
    http.end();
  } else {
    Serial.println("WiFi tidak terhubung.");
  }

  delay(5000);
}
