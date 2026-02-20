import 'package:flutter/material.dart';
import 'attendance_form_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Employee ID')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Enter Employee ID (e.g., CISS/TCS/2025-26/123)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Employee ID'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final id = _controller.text.trim();
                  if (id.isEmpty) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => AttendanceFormScreen(initialEmployeeId: id, scanMethod: 'manual')),
                  );
                },
                child: const Text('Continue'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
