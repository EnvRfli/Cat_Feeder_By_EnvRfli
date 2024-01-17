import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:getwidget/getwidget.dart';

class AppSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Pengaturan Makanan'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              BeriMakanWetFoodHariIni(),
              StockPage(),
              PengaturanPorsiMakanan(),
              PengaturanJadwalMakanan(),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDescription(BuildContext context, String title, String description) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext bc) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              controller: scrollController,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 100, right: 100, bottom: 20),
                  width: 10,
                  height: 5,
                  color: Colors.grey,
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Text(description),
              ],
            ),
          );
        },
      );
    },
  );
}

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  double stockValue = 10.0;
  double maxStockValue = 15.0;

  @override
  void initState() {
    super.initState();
    _loadStockValueFromFirebase();
  }

  void _loadStockValueFromFirebase() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('food_status');
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        stockValue = (double.tryParse(snapshot.value.toString()) ?? 5.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String stockStatus;
    Color stockColor;

    if (stockValue <= 5) {
      stockStatus = "Banyak";
      stockColor = Colors.green;
    } else if (stockValue <= 12) {
      stockStatus = "Sedang";
      stockColor = Colors.yellow;
    } else {
      stockStatus = "Sedikit";
      stockColor = Colors.red;
    }

    double progressBarWidth = ((maxStockValue - stockValue) / maxStockValue) *
        (MediaQuery.of(context).size.width - 32);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stok Tangki Dry Food',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  _showDescription(context, 'Stok Tangki Dry Food',
                      'Kontainer ini menunjukkan kepada Anda seberapa banyak makanan yang tersisa di dalam dispenser. Bar progres hijau menunjukkan persentase persediaan makanan yang tersisa berdasarkan kapasitas maksimum. Dengan mengamati bar progres ini, Anda dapat memastikan bahwa dispenser selalu memiliki cukup makanan untuk hewan peliharaan Anda. Ketika bar progres mendekati bagian merah, pertimbangkan untuk menambahkan lebih banyak makanan ke dalam dispenser.');
                },
                child: Icon(Icons.help_outline),
              )
            ],
          ),
          const Divider(
            color: Colors.black,
          ),
          SizedBox(height: 8),
          Stack(
            children: <Widget>[
              Container(
                height: 20,
                width: MediaQuery.of(context).size.width - 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 20,
                width: progressBarWidth,
                decoration: BoxDecoration(
                  color: stockColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            stockStatus,
            style: TextStyle(fontWeight: FontWeight.bold, color: stockColor),
          ),
        ],
      ),
    );
  }
}

class PengaturanPorsiMakanan extends StatefulWidget {
  @override
  _PengaturanPorsiMakananState createState() => _PengaturanPorsiMakananState();
}

class _PengaturanPorsiMakananState extends State<PengaturanPorsiMakanan> {
  Map<String, int> foodPortions = {'sedikit': 2, 'sedang': 4, 'banyak': 3};

  @override
  void initState() {
    super.initState();
    _loadFoodPortionsFromFirebase();
  }

  void _loadFoodPortionsFromFirebase() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('porsi_makanan');
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        foodPortions = Map<String, int>.from(snapshot.value as Map);
      });
    }
  }

  void _updatePortionToFirebase(String key, int value) {
    DatabaseReference refPorsiMakanan =
        FirebaseDatabase.instance.ref('porsi_makanan/$key');
    refPorsiMakanan.set(value);
    setState(() {
      foodPortions[key] = value;
    });

    _updateFoodPortionBasedOnActivePorsiMakan(key, value);
  }

  void _updateFoodPortionBasedOnActivePorsiMakan(String key, int value) {
    DatabaseReference refPorsiMakan =
        FirebaseDatabase.instance.ref('porsi_makan');
    refPorsiMakan.get().then((snapshot) {
      if (snapshot.exists && snapshot.value.toString().toLowerCase() == key) {
        DatabaseReference refFoodPortion =
            FirebaseDatabase.instance.ref('food_portion');
        refFoodPortion.set(value);
      }
    });
  }

  void incrementPortion(String key) {
    int currentVal = foodPortions.containsKey(key) ? foodPortions[key]! : 0;
    if ((key == "sedikit" && currentVal < 3) ||
        (key == "sedang" && currentVal < 4) ||
        (key == "banyak" && currentVal < 5)) {
      _updatePortionToFirebase(key, currentVal + 1);
    }
  }

  void decrementPortion(String key) {
    int currentVal = foodPortions.containsKey(key) ? foodPortions[key]! : 0;
    if ((key == "sedikit" && currentVal > 0) ||
        (key == "sedang" && currentVal > 2) ||
        (key == "banyak" && currentVal > 3)) {
      _updatePortionToFirebase(key, currentVal - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengaturan Porsi Makanan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  _showDescription(context, 'Pengaturan Porsi Makanan',
                      '''Memungkinkan Anda untuk mengatur durasi porsi makanan. Ada tiga kategori yang dapat Anda pilih: 'sedikit', 'sedang', dan 'banyak'. Setiap kategori memiliki batasan durasi tertentu:

'Sedikit': Durasi ini berkisar antara 0-3 detik. Ini direkomendasikan untuk memberikan porsi makanan yang lebih kecil, idealnya untuk hewan peliharaan yang sedang diet atau untuk makanan camilan.

'Sedang': Durasi ini berkisar antara 2-4 detik. Ini adalah porsi standar yang direkomendasikan untuk kebanyakan hewan peliharaan.

'Banyak': Durasi ini berkisar antara 3-5 detik. Ini adalah untuk memberikan porsi makanan yang lebih besar, mungkin untuk hewan peliharaan yang lebih aktif atau yang lebih besar ukurannya.

Anda dapat menambah atau mengurangi durasi dengan menekan tombol panah atas atau bawah. Adanya batasan ini memastikan bahwa Anda tidak memberikan terlalu sedikit atau terlalu banyak makanan kepada hewan peliharaan Anda, sehingga menjaga keseimbangan gizi yang tepat.''');
                },
                child: Icon(Icons.help_outline),
              )
            ],
          ),
          const Divider(
            color: Colors.black,
          ),
          ...foodPortions.keys.map((key) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(key),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_drop_up),
                      onPressed: () {
                        incrementPortion(key);
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(foodPortions[key]!.toString()),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_drop_down),
                      onPressed: () {
                        decrementPortion(key);
                      },
                    ),
                    const Text(' detik')
                  ],
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class PengaturanJadwalMakanan extends StatefulWidget {
  @override
  _PengaturanJadwalMakananState createState() =>
      _PengaturanJadwalMakananState();
}

class _PengaturanJadwalMakananState extends State<PengaturanJadwalMakanan> {
  Map<String, TimeOfDay> schedule = {
    'Pagi': TimeOfDay(hour: 7, minute: 0),
    'Siang': TimeOfDay(hour: 12, minute: 0),
    'Malam': TimeOfDay(hour: 18, minute: 0)
  };

  @override
  void initState() {
    super.initState();
    _loadScheduleFromFirebase();
  }

  void _loadScheduleFromFirebase() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> values =
          Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        schedule['Pagi'] = TimeOfDay(
            hour: values['Jadwal_Pagi_Jam'] ?? 7,
            minute: values['Jadwal_Pagi_Menit'] ?? 0);
        schedule['Siang'] = TimeOfDay(
            hour: values['Jadwal_Siang_Jam'] ?? 12,
            minute: values['Jadwal_Siang_Menit'] ?? 0);
        schedule['Malam'] = TimeOfDay(
            hour: values['Jadwal_Malam_Jam'] ?? 18,
            minute: values['Jadwal_Malam_Menit'] ?? 0);
      });
    }
  }

  TimeOfDay _convertToTimeOfDay(String? timeString) {
    if (timeString == null) return TimeOfDay(hour: 0, minute: 0);
    List<String> parts = timeString.split('.');
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _updateScheduleToFirebase(String key, TimeOfDay time) {
    DatabaseReference refJam =
        FirebaseDatabase.instance.ref('Jadwal_${key}_Jam');
    DatabaseReference refMenit =
        FirebaseDatabase.instance.ref('Jadwal_${key}_Menit');
    refJam.set(time.hour);
    refMenit.set(time.minute);
  }

  Future<void> _selectTime(BuildContext context, String key) async {
    final initialTime = schedule[key]!;
    TimeOfDay? pickedTime =
        await showTimePicker(context: context, initialTime: initialTime);

    if (pickedTime != null) {
      bool isTimeValid = true;
      String message = '';

      switch (key) {
        case 'Pagi':
          if (pickedTime.hour >= 12) {
            message =
                'Jadwal pagi hanya dapat diisi dengan rentang waktu 00:00 - 12:00';
            isTimeValid = false;
          }
          break;
        case 'Siang':
          if (pickedTime.hour < 11 || pickedTime.hour >= 17) {
            message =
                'Jadwal siang hanya dapat diisi dengan rentang waktu 11:00 - 17:00';
            isTimeValid = false;
          }
          break;
        case 'Malam':
          if (pickedTime.hour < 16 || pickedTime.hour >= 24) {
            message =
                'Jadwal malam hanya dapat diisi dengan rentang waktu 16:00 - 24:00';
            isTimeValid = false;
          }
          break;
      }

      if (!isTimeValid) {
        await _showTimeOutOfRangeDialog(context, message);
      } else {
        setState(() {
          schedule[key] = pickedTime;
        });
        _updateScheduleToFirebase(key, pickedTime);
      }
    }
  }

  Future<void> _showTimeOutOfRangeDialog(
      BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pemberitahuan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengaturan Jadwal Makanan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  _showDescription(context, 'Pengaturan Jadwal Makanan',
                      '''Memungkinkan Anda untuk menetapkan jadwal makanan. Ada tiga periode waktu yang bisa Anda atur: 'Pagi', 'Siang', dan 'Sore'.

'Pagi': Anda dapat mengatur waktu antara jam 0 hingga 12. Idealnya, waktu makan pagi harus diatur saat hewan peliharaan Anda biasanya bangun dan aktif.

'Siang': Anda dapat mengatur waktu antara jam 11 hingga 17. Ini memastikan bahwa hewan peliharaan Anda mendapatkan makan siang yang baik untuk menjaga energi mereka sepanjang hari.

'Sore': Anda dapat mengatur waktu antara jam 16 hingga 24. Ini adalah waktu ketika hewan peliharaan biasanya makan malam sebelum beristirahat malam.

Dengan mengetuk waktu yang ditampilkan, Anda akan dibawa ke pemilih waktu untuk menyesuaikan jam dan menit. Range waktu yang ditentukan memastikan bahwa Anda memberi makan hewan peliharaan Anda pada interval yang sehat sepanjang hari, menghindari pemberian makan terlalu sering atau terlalu jarang.''');
                },
                child: Icon(Icons.help_outline),
              )
            ],
          ),
          const Divider(
            color: Colors.black,
          ),
          ...schedule.keys.map((key) {
            return Card(
              child: InkWell(
                onTap: () {
                  _selectTime(context, key);
                },
                child: ListTile(
                  title: Text(key),
                  trailing: Text(schedule[key]!.format(context)),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 2, // Opsional, untuk memberikan efek bayangan
            );
          }).toList(),
        ],
      ),
    );
  }
}

class BeriMakanWetFoodHariIni extends StatefulWidget {
  @override
  _BeriMakanWetFoodHariIniState createState() =>
      _BeriMakanWetFoodHariIniState();
}

class _BeriMakanWetFoodHariIniState extends State<BeriMakanWetFoodHariIni> {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref('manganbasah');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Beri Makan Wet Food Hari Ini?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  _showDescription(context, 'Beri Makan Wet Food Hari Ini?',
                      'Pilihan ini memungkinkan Anda untuk mengatur apakah wet food (makanan basah) akan diberikan kepada hewan peliharaan Anda hari ini (pagi hari). Geser tombol ke kanan untuk mengaktifkan pemberian makanan basah hari ini, dan geser ke kiri untuk tidak memberikan. Ini memudahkan Anda dalam mengelola diet harian hewan peliharaan Anda, memastikan mereka mendapatkan variasi makanan yang sehat dan sesuai kebutuhan.');
                },
                child: Icon(Icons.help_outline),
              )
            ],
          ),
          const Divider(
            color: Colors.black,
          ),
          SizedBox(height: 10),
          Center(
            child: StreamBuilder<DatabaseEvent>(
              stream: databaseReference.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && !snapshot.hasError) {
                  final bool isWetFoodGivenToday =
                      (snapshot.data?.snapshot.value ?? false) as bool;
                  return GFToggle(
                    value: isWetFoodGivenToday,
                    onChanged: (val) =>
                        _updateWetFoodStatusInFirebase(val ?? false),
                    type: GFToggleType.custom,
                    enabledTrackColor: Colors.lightBlue,
                    disabledTrackColor: Colors.grey[300],
                    enabledThumbColor: Colors.blue,
                    disabledThumbColor: Colors.blue,
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder<DatabaseEvent>(
            stream: databaseReference.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && !snapshot.hasError) {
                final bool isWetFoodGivenToday =
                    (snapshot.data?.snapshot.value ?? false) as bool;
                String foodText = isWetFoodGivenToday
                    ? "Note : Jadwal pagi akan memberikan wet food, pastikan anda sudah menaruh wet food pada wadah yang telah disediakan"
                    : "Note : Jadwal pagi akan memberikan dry food";
                return Text(
                  foodText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                );
              } else {
                return SizedBox(); // Jika data belum tersedia, tampilkan widget kosong
              }
            },
          ),
        ],
      ),
    );
  }

  void _updateWetFoodStatusInFirebase(bool status) {
    databaseReference.set(status);
  }
}
