import 'package:cloud_firestore/cloud_firestore.dart';

class Site {
  final String id;
  final String siteName;
  final String clientName;
  final String district;
  final GeoPoint geolocation;

  Site({
    required this.id,
    required this.siteName,
    required this.clientName,
    required this.district,
    required this.geolocation,
  });

  factory Site.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Site(
      id: doc.id,
      siteName: data['siteName'] ?? '',
      clientName: data['clientName'] ?? '',
      district: data['district'] ?? '',
      geolocation: data['geolocation'] as GeoPoint,
    );
  }
}
