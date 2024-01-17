import 'package:flutter/material.dart';

class AboutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang Aplikasi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Image.asset(
                // Gantilah dengan logo atau gambar aplikasi Anda
                'images/kucing.png',
                height: 100.0,
                width: 100.0,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Automatic Cat Feeder oleh M. Rafli Agusta Rizalfa',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            const Text(
              'Aplikasi "Automatic Cat Feeder" merupakan Aplikasi yang dirancang khusus oleh M. Rafli Agusta Rizalfa. Aplikasi ini bertujuan untuk mengatasi masalah pemberian pakan kucing yang tidak teratur, terutama ketika pemilik kucing tidak ada di rumah karena kesibukan atau tugas lainnya.'
              '\n\nFitur-fitur utama dari aplikasi ini meliputi pengaturan jadwal pemberian pakan, pemantauan status dispenser makanan, serta pengaturan porsi makanan. Dengan adanya fitur-fitur ini, pemilik kucing dapat memastikan bahwa hewan peliharaannya mendapatkan asupan gizi yang tepat dan teratur.'
              '\n\nTerhubung dengan perangkat IoT, aplikasi ini memudahkan pemilik kucing untuk mengontrol pemberian makanan kucing dari jarak jauh. Aplikasi dan perangkat IoT terhubung dengan Firebase, memastikan sinkronisasi data secara real-time.'
              '\n\nDengan adanya aplikasi "Automatic Cat Feeder", pemilik kucing dapat merasa lebih tenang dan yakin bahwa kucing peliharaannya mendapatkan pakan dengan porsi yang sesuai, meskipun mereka tidak berada di rumah.',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
