import 'package:flutter/material.dart';
import 'package:catfeeder_flutterapp/cat_feeder_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("2818d30a-4e69-4b3f-89b5-d435749a7caa");
  OneSignal.Notifications.requestPermission(true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Feeder UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CatFeederScreen(),
    );
  }
}
