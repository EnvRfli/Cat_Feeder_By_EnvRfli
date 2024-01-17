#include <Arduino.h>
#include <Wire.h>
#include "RTClib.h"
#include <Servo.h>
#include <WiFi.h>
#include <FirebaseESP32.h> 

const char* ssid = "Rizalfa";
const char* password = "113333555555";

RTC_DS1307 rtc;
Servo servoMG996R; 
Servo servoSG95;  
Servo servodepan;
Servo servobelakang;

bool isManganBasahProcessed = false;

const int triggerPin = 26;
const int echoPin = 25;
const int waterLevelPin = 17;
const int waterpump = 33;
const int buzz = 10;

int hour;
int minute;

char JamStr[3];
char MenitStr[3];
char PagiJamStr[3];
char PagiMenitStr[3];
char SiangJamStr[3];
char SiangMenitStr[3];
char MalamJamStr[3];
char MalamMenitStr[3];
char TempJamStr[3];
char TempMenitStr[3];

unsigned long previousULTRMillis = 0;
const unsigned long ULTRInterval = 1000;

unsigned long previousRTCMillis = 0;
const unsigned long RTCInterval = 100; 

unsigned long previousWaterLevelMillis = 0;
const unsigned long WaterLevelInterval = 60000; 

unsigned long servoMoveMillis = 0;
const unsigned long servoMoveDuration = 5000; 

unsigned long lastFoodEmptyOutputMillis = 0;
const unsigned long FoodEmptyInterval = 10000;

unsigned long lastFoodGivenMillis = 0;
const unsigned long lastFoodGivenInterval = 60000;

unsigned long previousWaterPumpMillis = 0;
const unsigned long WaterPumpInterval = 3600000;


FirebaseData firebaseData; 

//akan digunakan pada proses fuzzy (jika terhubung ke wifi)
double PorsiMakan;
double KetersediaanMakan;
double JadwalMakan;
double JadwalPagi;
double JadwalSiang;
double JadwalMalam;
double TempJadwalMakan;
int JadwalPagiJam;
int JadwalPagiMenit;
int JadwalSiangJam;
int JadwalSiangMenit;
int JadwalMalamJam;
int JadwalMalamMenit;
int TempJam;
int TempMenit;

//akan digunakan pada proses fuzzy (jika tidak terhubung ke wifi)
double PorsiMakanDefault = 4.0;
double KetersediaanMakanDefault;
double JadwalPagiDefault = 8.0;
double JadwalSiangDefault = 12.30;
double JadwalMalamDefault = 19.0;
int JadwalPagiJamDefault = 8.0;
int JadwalPagiMenitDefault = 0;
int JadwalSiangJamDefault = 12.0;
int JadwalSiangMenitDefault = 30;
int JadwalMalamJamDefault = 19.0;
int JadwalMalamMenitDefault = 0;

double linierNaik(double x, double x0, double x1) {
    return (x <= x0) ? 0 : (x >= x1) ? 1 : (x - x0) / (x1 - x0);
}

double linierTurun(double x, double x0, double x1) {
    return (x <= x0) ? 1 : (x >= x1) ? 0 : (x1 - x) / (x1 - x0);
}

double segitiga(double x, double a, double b, double c) {
    return max(min((x - a) / (b - a), (c - x) / (c - b)), 0.0);
}

unsigned long wifiReconnectAttemptTime = 0;
const unsigned long wifiReconnectInterval = 60000; // 60 seconds

bool useDefaultSettings = false;

void connectToWiFi() {
  unsigned long startTime = millis();
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    if (millis() - startTime > wifiReconnectInterval) {
      useDefaultSettings = true;
      break;
    }
  }
  
  if (useDefaultSettings) {
    Serial.println("Failed to connect to WiFi. Using default settings.");
    PorsiMakan = PorsiMakanDefault;
    KetersediaanMakan = KetersediaanMakanDefault;
    JadwalPagi = JadwalPagiDefault;
    JadwalSiang = JadwalSiangDefault;
    JadwalMalam = JadwalMalamDefault;

  } else {
    Serial.println("Connected to WiFi.");
    Firebase.begin("https://catfeederta-default-rtdb.asia-southeast1.firebasedatabase.app", "AIzaSyD_Yd9Xrt2dvpnawKrPy7JicFGB08gKdyU");
  }
}

void setup() {
  Serial.begin(9600);
  pinMode(triggerPin, OUTPUT);
  pinMode(waterpump, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(waterLevelPin, INPUT);
  pinMode(buzz, OUTPUT);

  digitalWrite(waterpump, HIGH);

  lastFoodEmptyOutputMillis =- FoodEmptyInterval;
  lastFoodGivenMillis =- lastFoodGivenInterval;
  previousWaterLevelMillis =- WaterLevelInterval;
  previousWaterPumpMillis =- WaterPumpInterval;

  servoSG95.attach(27);   
  servodepan.attach(32); 
  servobelakang.attach(13);

  Wire.begin();

  connectToWiFi();

  if (!rtc.begin()) {
    Serial.println("Modul RTC not found!");
    while (1);
  }

  if (!rtc.isrunning()) {
    Serial.println("RTC not running. Setting time...");
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

}

void loop() {

  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiReconnectAttemptTime > wifiReconnectInterval) {
      wifiReconnectAttemptTime = millis();
      connectToWiFi();
    }
  }

  // Mengambil data /food_status dari Firebase
  if (Firebase.getFloat(firebaseData, "/food_status")) {
    if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
      KetersediaanMakan = round(firebaseData.floatData()); // Pembulatan nilai
      Serial.print("Ketersediaan Makanan : ");
      Serial.println(KetersediaanMakan);
    }
  } else {
    Serial.println("Failed to get food status");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

  // Mengambil data /food_portion dari Firebase
  if (Firebase.getInt(firebaseData, "/food_portion")) {
    if (firebaseData.dataType() == "int") {
      PorsiMakan = static_cast<double>(firebaseData.intData());
      Serial.print("Porsi Makan : ");
      Serial.println(PorsiMakan);
    }

  } else {
    Serial.println("Failed to get food portion");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

  if (Firebase.getInt(firebaseData, "/Jadwal_Pagi_Jam")) {
    if (firebaseData.dataType() == "int") {
      JadwalPagiJam = static_cast<int>(firebaseData.intData());
      sprintf(PagiJamStr, "%02d", JadwalPagiJam);
      Serial.print("Jadwal Pagi Jam : ");
      Serial.println(PagiJamStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Pagi Jam");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

  if (Firebase.getInt(firebaseData, "/Jadwal_Pagi_Menit")) {
    if (firebaseData.dataType() == "int") {
      JadwalPagiMenit = static_cast<int>(firebaseData.intData());
      sprintf(PagiMenitStr, "%02d", JadwalPagiMenit);
      Serial.print("Jadwal Pagi Menit : ");
      Serial.println(PagiMenitStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Pagi Menit");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

//  if (Firebase.getFloat(firebaseData, "/Jadwal_Pagi")) {
//     if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
//         JadwalPagi = static_cast<double>(firebaseData.floatData()); // Mengambil data float
//         Serial.print("Jadwal Pagi : ");
//         Serial.println(JadwalPagi, 2);
//     }
//   } else {
//       // Jika gagal mengambil data, cetak pesan kesalahan
//       Serial.println("Failed to get Jadwal Pagi");
//       Serial.println("Reason: " + firebaseData.errorReason());
//   }

  if (Firebase.getInt(firebaseData, "/Jadwal_Siang_Jam")) {
    if (firebaseData.dataType() == "int") {
      JadwalSiangJam = static_cast<int>(firebaseData.intData());
      sprintf(SiangJamStr, "%02d", JadwalSiangJam);
      Serial.print("Jadwal Siang Jam : ");
      Serial.println(SiangJamStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Siang Jam");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

  if (Firebase.getInt(firebaseData, "/Jadwal_Siang_Menit")) {
    if (firebaseData.dataType() == "int") {
      JadwalSiangMenit = static_cast<int>(firebaseData.intData());
      sprintf(SiangMenitStr, "%02d", JadwalSiangMenit);
      Serial.print("Jadwal Siang Menit : ");
      Serial.println(SiangMenitStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Siang Menit");
    Serial.println("Reason: " + firebaseData.errorReason());
  }
  
//   if (Firebase.getFloat(firebaseData, "/Jadwal_Siang")) {
//     if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
//         JadwalSiang = static_cast<double>(firebaseData.floatData()); // Mengambil data float
//         Serial.print("Jadwal Pagi : ");
//         Serial.println(JadwalSiang, 2);
//     }
//   } else {
//       // Jika gagal mengambil data, cetak pesan kesalahan
//       Serial.println("Failed to get Jadwal Siang");
//       Serial.println("Reason: " + firebaseData.errorReason());
//   }

  if (Firebase.getInt(firebaseData, "/Jadwal_Malam_Jam")) {
    if (firebaseData.dataType() == "int") {
      JadwalMalamJam = static_cast<int>(firebaseData.intData());
      sprintf(MalamJamStr, "%02d", JadwalMalamJam);
      Serial.print("Jadwal Malam Jam : ");
      Serial.println(MalamJamStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Malam Jam");
    Serial.println("Reason: " + firebaseData.errorReason());
  }

  if (Firebase.getInt(firebaseData, "/Jadwal_Malam_Menit")) {
    if (firebaseData.dataType() == "int") {
      JadwalMalamMenit = static_cast<int>(firebaseData.intData());
      sprintf(MalamMenitStr, "%02d", JadwalMalamMenit);
      Serial.print("Jadwal Malam Menit : ");
      Serial.println(MalamMenitStr);
    }

  } else {
    Serial.println("Failed to get Jadwal Malam Menit");
    Serial.println("Reason: " + firebaseData.errorReason());
  }


  // if (Firebase.getInt(firebaseData, "/tempJam")) {
  //   if (firebaseData.dataType() == "int") {
  //     TempJam = static_cast<int>(firebaseData.intData());
  //     sprintf(TempJamStr, "%02d", TempJam);
  //     Serial.print("TEMP JAM Jam : ");
  //     Serial.println(TempJamStr);
  //   }

  // } else {
  //   // Jika gagal mengambil data, cetak pesan kesalahan
  //   Serial.println("Failed to get Jadwal Malam Jam");
  //   Serial.println("Reason: " + firebaseData.errorReason());
  // }

  // if (Firebase.getInt(firebaseData, "/tempMenit")) {
  //   if (firebaseData.dataType() == "int") {
  //     TempMenit = static_cast<int>(firebaseData.intData());
  //     sprintf(TempMenitStr, "%02d", TempMenit);
  //     Serial.print("TEMP MENIT Menit : ");
  //     Serial.println(TempMenitStr);
  //   }

  // } else {
  //   // Jika gagal mengambil data, cetak pesan kesalahan
  //   Serial.println("Failed to get Jadwal Malam Menit");
  //   Serial.println("Reason: " + firebaseData.errorReason());
  // }

// if (Firebase.getFloat(firebaseData, "/tempjadwalmakan")) {
//     if (firebaseData.dataType() == "int" || firebaseData.dataType() == "float") {
//       TempJadwalMakan = static_cast<double>(firebaseData.intData());
//       Serial.print("TEMP JADWAL MAKAN AKWLAKSLKALSK : ");
//       Serial.println(TempJadwalMakan);
//     }

//   } else {
//     // Jika gagal mengambil data, cetak pesan kesalahan
//     Serial.println("Failed to get Jadwal Malam Menit");
//     Serial.println("Reason: " + firebaseData.errorReason());
//   }

  
  // if (Firebase.getFloat(firebaseData, "/Jadwal_Malam")) {
  //   if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
  //       JadwalMalam = static_cast<double>(firebaseData.floatData()); // Mengambil data float
  //       Serial.print("Jadwal Malam : ");
  //       Serial.println(JadwalMalam, 2);
  //   }
  // } else {
  //     // Jika gagal mengambil data, cetak pesan kesalahan
  //     Serial.println("Failed to get Jadwal Malam");
  //     Serial.println("Reason: " + firebaseData.errorReason());
  // }

  unsigned long currentULTRMillis = millis();

  if (currentULTRMillis - previousULTRMillis >= ULTRInterval) {
    previousULTRMillis = currentULTRMillis;

    digitalWrite(triggerPin, LOW);
    delayMicroseconds(2);
    digitalWrite(triggerPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(triggerPin, LOW);

    long duration = pulseIn(echoPin, HIGH);
    float distance = (duration / 2.0) * 0.0343;
    KetersediaanMakanDefault = distance;

    if (currentULTRMillis - lastFoodEmptyOutputMillis >= FoodEmptyInterval) {
      lastFoodEmptyOutputMillis = currentULTRMillis;
      
      if (Firebase.setFloat(firebaseData, "/food_status", distance)) {
        Serial.println("Data updated in firebase!");
      } else {
        Serial.println("Failed to update data in firebase");
        Serial.println("Reason: " + firebaseData.errorReason());
      }

      if(distance > 12){
        Serial.println("Food empty");
      }
    }

    DateTime now = rtc.now(); 

    char JadwalMakanStr[6]; 
    hour = now.hour();
    minute = now.minute();

    sprintf(JadwalMakanStr, "%02d.%02d", hour, minute);
    sprintf(JamStr, "%02d", hour);
    sprintf(MenitStr, "%02d", minute);

    Serial.print("Jam Sekarang: ");
    Serial.println(JadwalMakanStr);
    Serial.print("JAMSTR Sekarang: ");
    Serial.println(JamStr);
    Serial.print("MENITSTR Sekarang: ");
    Serial.println(MenitStr);
    JadwalMakan = hour;
  }

  unsigned long currentWaterLevelMillis = millis();
  if (currentWaterLevelMillis - previousWaterLevelMillis >= WaterLevelInterval) {
    previousWaterLevelMillis = currentWaterLevelMillis;

    // Lakukan pembacaan sensor water level di sini
    int waterLevelValue = digitalRead(waterLevelPin);
    Serial.print("Sensor Water Level: ");
    Serial.println(waterLevelValue);

    if (waterLevelValue == 0){
      unsigned long currentWaterPumpMillis = millis();
      if(currentWaterPumpMillis - previousWaterPumpMillis >= WaterPumpInterval){
        previousWaterPumpMillis = currentWaterPumpMillis;
        digitalWrite(waterpump, LOW);
        delay(5000);
        digitalWrite(waterpump, HIGH);
      }
    }
  }

  if (Firebase.getBool(firebaseData, "mangan_bang") && firebaseData.dataType() == "boolean") {
    if (firebaseData.boolData() == true) {
      tone(buzz, 1000); 
      delay(500);   
      noTone(buzz); 
      delay(500);    
      tone(buzz, 1000); 
      delay(500);     
      noTone(buzz);  
      delay(500);     
      servoMG996R.attach(14);
      servoMG996R.writeMicroseconds(2000);
      delay(PorsiMakan * 1000);
      servoMG996R.detach();
      delay(1000);
      servoSG95.write(180);
      delay(1000);
      servoMG996R.attach(14);
      servoMG996R.writeMicroseconds(2000);
      delay(PorsiMakan * 1000);
      servoMG996R.detach();
      delay(1000);
      servoSG95.write(0);
      delay(1000);

      Firebase.setBool(firebaseData, "mangan_bang", false);
    }
  }

  if (Firebase.getBool(firebaseData, "bukawetfood") && firebaseData.dataType() == "boolean") {
    if (firebaseData.boolData() == true && !isManganBasahProcessed) {
      for (int posDepan = 0, posBelakang = 80; posDepan <= 80; posDepan++, posBelakang--) {
        servodepan.write(posDepan);
        servobelakang.write(posBelakang);
        delay(50);
      }
      isManganBasahProcessed = true; 
    } else if (firebaseData.boolData() == false && isManganBasahProcessed) {
      for (int posDepan = 80, posBelakang = 0; posDepan >= 0; posDepan--, posBelakang++) {
        servodepan.write(posDepan);
        servobelakang.write(posBelakang);
        delay(50);
      }
      isManganBasahProcessed = false;
    }
  }

  //HERE COMES THE FUZZY LOGIC

  if ((strcmp(JamStr, PagiJamStr) == 0 && strcmp(MenitStr, PagiMenitStr) == 0) ||
    (strcmp(JamStr, SiangJamStr) == 0 && strcmp(MenitStr, SiangMenitStr) == 0) ||
    (strcmp(JamStr, MalamJamStr) == 0 && strcmp(MenitStr, MalamMenitStr) == 0)) {

    // if ((strcmp(TempJamStr, PagiJamStr) == 0 && strcmp(TempMenitStr, PagiMenitStr) == 0) ||
    // (strcmp(TempJamStr, SiangJamStr) == 0 && strcmp(TempMenitStr, SiangMenitStr) == 0) ||
    // (strcmp(TempJamStr, MalamJamStr) == 0 && strcmp(TempMenitStr, MalamMenitStr) == 0)) {
      
    unsigned long currentFoodGivenMillis = millis();
      if (currentFoodGivenMillis - lastFoodGivenMillis >= lastFoodGivenInterval) {
        lastFoodGivenMillis = currentFoodGivenMillis;
        double sedikit = linierTurun(PorsiMakan, 0, 3);
        double sedangMakan = segitiga(PorsiMakan, 2, 3, 4);
        double banyakMakan = linierNaik(PorsiMakan, 3, 5);

        double banyakKetersediaan = linierTurun(KetersediaanMakan, 5, 0);
        double sedangKetersediaan = segitiga(KetersediaanMakan, 4, 9, 14);
        double habis = linierNaik(KetersediaanMakan, 12, 15);

        // Jadwal makan
        double pagi = linierTurun(JadwalMakan, 12, 0);
        double siang = segitiga(JadwalMakan, 11, 14, 17);
        double malam = linierNaik(JadwalMakan, 16, 24);

        // double pagi = linierTurun(TempJadwalMakan, 12, 0);
        // double siang = segitiga(TempJadwalMakan, 11, 14, 17);
        // double malam = linierNaik(TempJadwalMakan, 16, 24);

        Serial.print('Porsi Makan Sedikit = ');
        Serial.println(sedikit);
        Serial.print('Porsi Makan Sedang = ');
        Serial.println(sedangMakan);
        Serial.print('Porsi Makan Banyak = ');
        Serial.println(banyakMakan);
        Serial.print('ketersediaan Makan banyak = ');
        Serial.println(banyakKetersediaan);
        Serial.print('ketersediaan Makan sedang = ');
        Serial.println(sedangKetersediaan);
        Serial.print('ketersediaan Makan habis = ');
        Serial.println(habis);
        Serial.print('jadwal Makan pagi = ');
        Serial.println(pagi);
        Serial.print('jadwal Makan siang = ');
        Serial.println(siang);
        Serial.print('jadwal Makan malam = ');
        Serial.println(malam);


        double ruleValues[27];

        // Rule 1
        ruleValues[0] = min(banyakMakan, min(banyakKetersediaan, pagi));

        // Rule 2
        ruleValues[1] = min(banyakMakan, min(banyakKetersediaan, siang));

        // Rule 3
        ruleValues[2] = min(banyakMakan, min(banyakKetersediaan, malam));

        // Rule 4
        ruleValues[3] = min(banyakMakan, min(sedangKetersediaan, pagi));

        // Rule 5
        ruleValues[4] = min(banyakMakan, min(sedangKetersediaan, siang));

        // Rule 6
        ruleValues[5] = min(banyakMakan, min(sedangKetersediaan, malam));

        // Rule 7
        ruleValues[6] = min(banyakMakan, min(habis, pagi));

        // Rule 8
        ruleValues[7] = min(banyakMakan, min(habis, siang));

        // Rule 9
        ruleValues[8] = min(banyakMakan, min(habis, malam));

        // Rule 10
        ruleValues[9] = min(sedangMakan, min(banyakKetersediaan, pagi));

        // Rule 11
        ruleValues[10] = min(sedangMakan, min(banyakKetersediaan, siang));

        // Rule 12
        ruleValues[11] = min(sedangMakan, min(banyakKetersediaan, malam));

        // Rule 13
        ruleValues[12] = min(sedangMakan, min(sedangKetersediaan, pagi));

        // Rule 14
        ruleValues[13] = min(sedangMakan, min(sedangKetersediaan, siang));

        // Rule 15
        ruleValues[14] = min(sedangMakan, min(sedangKetersediaan, malam));

        // Rule 16
        ruleValues[15] = min(sedangMakan, min(habis, pagi));

        // Rule 17
        ruleValues[16] = min(sedangMakan, min(habis, siang));

        // Rule 18
        ruleValues[17] = min(sedangMakan, min(habis, malam));

        // Rule 19
        ruleValues[18] = min(sedikit, min(banyakKetersediaan, pagi));

        // Rule 20
        ruleValues[19] = min(sedikit, min(banyakKetersediaan, siang));

        // Rule 21
        ruleValues[20] = min(sedikit, min(banyakKetersediaan, malam));

        // Rule 22
        ruleValues[21] = min(sedikit, min(sedangKetersediaan, pagi));

        // Rule 23
        ruleValues[22] = min(sedikit, min(sedangKetersediaan, siang));

        // Rule 24
        ruleValues[23] = min(sedikit, min(sedangKetersediaan, malam));

        // Rule 25
        ruleValues[24] = min(sedikit, min(habis, pagi));

        // Rule 26
        ruleValues[25] = min(sedikit, min(habis, siang));

        // Rule 27
        ruleValues[26] = min(sedikit, min(habis, malam));

        for(int i = 0; i <= 26; i++){
          Serial.println(ruleValues[i]);
        }

        double noFood = 0.0;
        double dryFood = 0.0;
        double wetFood = 0.0;

        double noFoodWeights[] = {ruleValues[7], ruleValues[8], ruleValues[16], ruleValues[17], ruleValues[25], ruleValues[26]};
        double dryFoodWeights[] = {ruleValues[1], ruleValues[2], ruleValues[4], ruleValues[5], ruleValues[10], ruleValues[11], ruleValues[13], ruleValues[14], ruleValues[19], ruleValues[20], ruleValues[22], ruleValues[23]};
        double wetFoodWeights[] = {ruleValues[0], ruleValues[3], ruleValues[6], ruleValues[9], ruleValues[12], ruleValues[15], ruleValues[18], ruleValues[21], ruleValues[24]};

        for (unsigned int i = 0; i < sizeof(noFoodWeights) / sizeof(noFoodWeights[0]); i++) {
            noFood += noFoodWeights[i];
        }
        for (unsigned int i = 0; i < sizeof(dryFoodWeights) / sizeof(dryFoodWeights[0]); i++) {
            dryFood += dryFoodWeights[i];
        }
        for (unsigned int i = 0; i < sizeof(wetFoodWeights) / sizeof(wetFoodWeights[0]); i++) {
            wetFood += wetFoodWeights[i];
        }

        if (noFood >= dryFood && noFood >= wetFood) {
        // Mengirim notifikasi ke Firebase bahwa makanan habis
          Serial.println("Tidak Memberi Makan");
          if (Firebase.setString(firebaseData, "/notif_kosong", "Makanan habis")) {
            Serial.println("Notifikasi 'Makanan habis' terkirim ke Firebase");
          } else {
            Serial.println("Gagal mengirim notifikasi ke Firebase");
          }
        } else if (dryFood > noFood && dryFood >= wetFood) {
            // Menggerakkan motor DC selama PorsiMakan detik
            Serial.println("Beri Makan Dry Food");
            tone(buzz, 1000); 
            delay(500);   
            noTone(buzz); 
            delay(500);    
            tone(buzz, 1000); 
            delay(500);     
            noTone(buzz);  
            delay(500);  
            servoMG996R.attach(14);
            servoMG996R.writeMicroseconds(2000);
            delay(PorsiMakan * 1000);
            servoMG996R.detach();
            delay(1000);
            servoSG95.write(180);
            delay(1000);
            servoMG996R.attach(14);
            servoMG996R.writeMicroseconds(2000);
            delay(PorsiMakan * 1000);
            servoMG996R.detach();
            delay(1000);
            servoSG95.write(0);
            delay(1000);
        } else {
          if (Firebase.getBool(firebaseData, "manganbasah") && firebaseData.dataType() == "boolean") {
            if (firebaseData.boolData() == true) {
              Serial.println("Memberi Makan Wet Food");
              tone(buzz, 1000); 
              delay(500);   
              noTone(buzz); 
              delay(500);    
              tone(buzz, 1000); 
              delay(500);     
              noTone(buzz);  
              delay(500);     
              for (int posDepan = 0, posBelakang = 80; posDepan <= 80; posDepan++, posBelakang--) {
                servodepan.write(posDepan);
                servobelakang.write(posBelakang);
                delay(50);
              }
            }
            else{
              if(KetersediaanMakan <= 12){
                Serial.println("Beri Makan Dry Food");
                tone(buzz, 1000); 
                delay(500);   
                noTone(buzz); 
                delay(500);    
                tone(buzz, 1000); 
                delay(500);     
                noTone(buzz);  
                delay(500);    
                servoMG996R.attach(14);
                servoMG996R.writeMicroseconds(2000);
                delay(PorsiMakan * 1000);
                servoMG996R.detach();
                delay(1000);
                servoSG95.write(180);
                delay(1000);
                servoMG996R.attach(14);
                servoMG996R.writeMicroseconds(2000);
                delay(PorsiMakan * 1000);
                servoMG996R.detach();
                delay(1000);
                servoSG95.write(0);
                delay(1000);
              }
              else{
                Serial.println("Tidak Memberi Makan");
                if (Firebase.setString(firebaseData, "/notif_kosong", "Makanan habis")) {
                  Serial.println("Notifikasi 'Makanan habis' terkirim ke Firebase");
                } else {
                  Serial.println("Gagal mengirim notifikasi ke Firebase");
                }
              }
            }       
          }
        }
      }
  }
  delay(5000);
}
