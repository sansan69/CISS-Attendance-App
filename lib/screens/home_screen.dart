import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CISS-Kerala Attendance'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Image.asset('assets/logo.png', height: 80),
            const SizedBox(height: 24),
            const Text(
              'Mark Attendance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Scan QR'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Enter Employee ID'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Attendance List / Submit'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Geofence + full photo required.\nAuto-selects nearest site; you can change it.',
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
