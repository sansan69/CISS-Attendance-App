import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/site.dart';
import '../services/firestore_service.dart';
import '../utils/geo.dart';
import '../utils/overlay.dart';

class AttendanceFormScreen extends StatefulWidget {
  final String initialEmployeeId;
  final String scanMethod; // qr/manual

  const AttendanceFormScreen({super.key, required this.initialEmployeeId, required this.scanMethod});

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  final _firestore = FirestoreService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  final List<TextEditingController> _employeeIds = [];
  bool _useSamePhoto = true;
  bool _submitting = false;

  Position? _position;
  List<Site> _sites = [];
  Site? _selectedSite;
  File? _photo;

  @override
  void initState() {
    super.initState();
    _employeeIds.add(TextEditingController(text: widget.initialEmployeeId));
    _loadSitesAndLocation();
  }

  Future<void> _loadSitesAndLocation() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) {
        _show('Location permission is required to auto‑select site.');
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _show('Please enable Location (GPS).');
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final sites = await _firestore.fetchSites();
      setState(() {
        _position = pos;
        _sites = sites;
        _selectedSite = _autoSelectSite(sites, pos);
      });
    } catch (e) {
      setState(() {
        _sites = [];
      });
      _show('Could not load location or sites. Please try again.');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return false;
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Site? _autoSelectSite(List<Site> sites, Position pos) {
    if (sites.isEmpty) return null;
    Site? nearest;
    double? bestDist;
    for (final s in sites) {
      final d = distanceMeters(pos.latitude, pos.longitude, s.geolocation.latitude, s.geolocation.longitude);
      if (bestDist == null || d < bestDist) {
        bestDist = d;
        nearest = s;
      }
    }
    return nearest;
  }

  Future<void> _capturePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90, preferredCameraDevice: CameraDevice.rear);
    if (image == null) return;

    final file = File(image.path);
    if (_position != null && _selectedSite != null) {
      final withOverlay = await addOverlayToImage(file,
          lat: _position!.latitude,
          lng: _position!.longitude,
          siteName: _selectedSite!.siteName);
      setState(() => _photo = withOverlay);
    } else {
      setState(() => _photo = file);
    }
  }

  Future<void> _submit() async {
    if (_selectedSite == null || _photo == null || _employeeIds.any((c) => c.text.trim().isEmpty)) {
      _show('Please complete all fields and capture photo.');
      return;
    }
    setState(() => _submitting = true);

    try {
      final groupId = _uuid.v4();
      final now = DateTime.now();
      final filename = '${now.toIso8601String()}_${groupId}.jpg';

      final photoUrl = await _firestore.uploadAttendancePhoto(_photo!, filename);

      final primaryId = _employeeIds.first.text.trim();
      for (final c in _employeeIds) {
        final employeeId = c.text.trim();
        final emp = await _firestore.fetchEmployeeByEmployeeId(employeeId);

        final data = {
          'employeeId': employeeId,
          'employeeName': emp?['fullName'] ?? null,
          'clientName': emp?['clientName'] ?? null,
          'siteId': _selectedSite!.id,
          'siteName': _selectedSite!.siteName,
          'siteClient': _selectedSite!.clientName,
          'markedAt': now,
          'markedBy': primaryId,
          'scanMethod': widget.scanMethod,
          'groupId': groupId,
          'photoUrl': photoUrl,
          'location': {
            'lat': _position?.latitude,
            'lng': _position?.longitude,
          },
          'device': 'android',
          'app': 'CISS-Kerala'
        };
        await _firestore.createAttendanceLog(data);
      }

      _show('Attendance submitted successfully.');
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _show('Failed to submit attendance. Please try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guard IDs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._employeeIds.asMap().entries.map((entry) {
              final i = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: i == 0 ? 'Primary Guard ID' : 'Guard ID ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _employeeIds.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Add another guard'),
            ),
            const Divider(height: 28),

            const Text('Location & Site', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_position != null)
              Text('Location: ${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Site>(
              value: _selectedSite,
              items: _sites.map((s) => DropdownMenuItem(value: s, child: Text('${s.siteName} (${s.clientName})'))).toList(),
              onChanged: (s) => setState(() => _selectedSite = s),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Site'),
            ),
            if (_sites.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No sites loaded. Please check network or permissions.', style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            const Text('Nearest site is auto‑selected. You can change it if needed.', style: TextStyle(color: Colors.black54)),
            const Divider(height: 28),

            const Text('Photo (Full Body)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(value: _useSamePhoto, onChanged: (v) => setState(() => _useSamePhoto = v)),
                const Text('Use same photo for all guards')
              ],
            ),
            const SizedBox(height: 8),
            if (_photo != null)
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photo!, height: 220, fit: BoxFit.cover)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Photo'),
                onPressed: _capturePhoto,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Photo will include timestamp and GPS overlay.', style: TextStyle(color: Colors.black54)),
            const Divider(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const CircularProgressIndicator() : const Text('Submit Attendance'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
