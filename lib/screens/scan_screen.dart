import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'attendance_form_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final raw = barcodes.first.rawValue ?? '';
          // Expecting format with Employee ID inside
          final match = RegExp(r'Employee ID:\s*(.+)') .firstMatch(raw);
          final id = match?.group(1)?.trim() ?? raw.trim();
          if (id.isEmpty) return;
          setState(() => _scanned = true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AttendanceFormScreen(initialEmployeeId: id, scanMethod: 'qr')),
          );
        },
      ),
    );
  }
}
