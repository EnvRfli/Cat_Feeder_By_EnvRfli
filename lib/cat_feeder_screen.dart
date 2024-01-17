import 'package:flutter/material.dart';
import 'package:catfeeder_flutterapp/halaman_settings.dart';
import 'package:catfeeder_flutterapp/halaman_tentang_aplikasi.dart';
import 'package:firebase_database/firebase_database.dart';

class CatFeederScreen extends StatefulWidget {
  @override
  _CatFeederScreenState createState() => _CatFeederScreenState();
}

class _CatFeederScreenState extends State<CatFeederScreen> {
  String activeButton = '';

  @override
  void initState() {
    super.initState();
    _getPorsiMakanFromFirebase();
  }

  DateTime? lastButtonPressTime;

  void _getPorsiMakanFromFirebase() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("porsi_makan");
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        activeButton = snapshot.value.toString();
      });
    } else {
      print("Data porsi makan tidak ditemukan di Firebase.");
    }
  }

  void _updateFoodPortionBasedOnPorsiMakan(String porsiMakan) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('porsi_makanan');
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      Map<String, int> porsiMap = Map<String, int>.from(snapshot.value as Map);
      int portionValue = porsiMap[porsiMakan.toLowerCase()] ?? 0;
      DatabaseReference portionRef =
          FirebaseDatabase.instance.ref('food_portion');
      portionRef.set(portionValue);
    }
  }

  void _updatePorsiMakanToFirebase(String porsi) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("porsi_makan");
    ref.set(porsi);
    setState(() {
      activeButton = porsi;
    });

    // Update food portion based on porsi makan
    _updateFoodPortionBasedOnPorsiMakan(porsi);
  }

  bool isWetFoodContainerOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 30,
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      AppSettings(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                          Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.ease))),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white, // Warna garis pinggir lingkaran
                width: 2.0, // Lebar garis pinggir lingkaran
              ),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutApp()),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.8),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, right: 30, left: 30),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Automatic Cat Feeder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Spacer(flex: 1),
                Container(
                  width: 200.0,
                  height: 200.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('images/kucing.png'),
                    ),
                  ),
                ),
                Spacer(
                  flex: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        "Pilih Porsi yang anda inginkan",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomButton(
                        text: 'Sedikit',
                        isActive: activeButton == 'Sedikit',
                        onPressed: () {
                          _updatePorsiMakanToFirebase('Sedikit');
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'Sedang',
                        isActive: activeButton == 'Sedang',
                        onPressed: () {
                          _updatePorsiMakanToFirebase('Sedang');
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'Banyak',
                        isActive: activeButton == 'Banyak',
                        onPressed: () {
                          _updatePorsiMakanToFirebase('Banyak');
                        },
                      ),
                    ),
                  ],
                ),

                Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        "Kontrol Alat",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    _showConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Beri Makan Sekarang',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                // Tombol untuk mengontrol wadah wet food
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('bukawetfood').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && !snapshot.hasError) {
                      bool localIsWetFoodContainerOpen =
                          (snapshot.data?.snapshot.value ?? false) as bool;
                      return ElevatedButton(
                        onPressed: () => _updateBukaWetFoodStatusFirebase(
                            !localIsWetFoodContainerOpen),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          localIsWetFoodContainerOpen
                              ? 'Tutup Wadah Wet Food'
                              : 'Buka Wadah Wet Food',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateManganBangStatus(bool status) async {
    if (lastButtonPressTime != null &&
        DateTime.now().difference(lastButtonPressTime!).inSeconds < 15) {
      _showWarningDialog(context);
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref('mangan_bang');
    await ref.set(status);
    lastButtonPressTime = DateTime.now();
  }

  void _updateBukaWetFoodStatusFirebase(bool status) async {
    if (lastButtonPressTime != null &&
        DateTime.now().difference(lastButtonPressTime!).inSeconds < 15) {
      _showWarningDialog(context);
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref('bukawetfood');
    await ref.set(status);
    lastButtonPressTime = DateTime.now();
  }

  void _showConfirmationDialog(BuildContext context) {
    if (lastButtonPressTime != null &&
        DateTime.now().difference(lastButtonPressTime!).inMinutes < 1) {
      // Tampilkan peringatan jika tombol ditekan dalam kurun waktu kurang dari 1 menit
      _showWarningDialog(context);
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Peringatan'),
          content: Text('Apakah anda yakin memberi makan sekarang?'),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ya, Lanjutkan'),
              onPressed: () {
                _updateManganBangStatus(true);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Peringatan'),
          content: Text('mohon tunggu 15 detik'),
          actions: <Widget>[
            TextButton(
              child: Text('Mengerti'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;

  CustomButton({
    required this.text,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: isActive ? Colors.yellow : Colors.lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
