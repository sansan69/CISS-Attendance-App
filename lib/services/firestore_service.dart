import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/site.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Site>> fetchSites() async {
    final snap = await _db.collection('sites').get();
    return snap.docs.map((d) => Site.fromDoc(d)).toList();
  }

  Future<Map<String, dynamic>?> fetchEmployeeByEmployeeId(String employeeId) async {
    final q = await _db.collection('employees').where('employeeId', isEqualTo: employeeId).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  Future<String> uploadAttendancePhoto(File file, String filename) async {
    final ref = _storage.ref().child('attendanceMobilePhotos/$filename');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> createAttendanceLog(Map<String, dynamic> data) async {
    await _db.collection('attendanceMobileLogs').add(data);
  }
}
