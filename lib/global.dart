import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
    DatabaseReference ref = FirebaseDatabase.instance.ref('porsi_makanan/$key');
    ref.set(value);
    setState(() {
      foodPortions[key] = value;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Porsi Makanan'),
      ),
      body: Container(
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
      ),
    );
  }
}
