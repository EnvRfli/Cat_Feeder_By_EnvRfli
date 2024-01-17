import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    // Meminta izin (utamanya untuk iOS)
    await _messaging.requestPermission();

    // Menangani pesan saat aplikasi berada di latar belakang
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Menyimpan token FCM (untuk mengidentifikasi setiap device)
    String? token = await _messaging.getToken();
    print("FCM Token: $token");

    // Menangani pesan saat aplikasi dibuka dari notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // TODO: Navigasi atau logika lain jika diperlukan
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Tidak perlu memanggil Firebase.initializeApp() di sini
    print('Handling a background message: ${message.messageId}');
    // Tambahkan logika untuk menangani pesan latar belakang jika diperlukan
  }
}
