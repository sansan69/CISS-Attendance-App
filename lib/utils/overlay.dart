import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

Future<File> addOverlayToImage(File input, {required double lat, required double lng, required String siteName}) async {
  final bytes = await input.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return input;

  final now = DateTime.now();
  final timestamp = DateFormat('dd-MM-yyyy HH:mm:ss').format(now);
  final text = 'Site: $siteName\nLat: ${lat.toStringAsFixed(6)}  Lng: ${lng.toStringAsFixed(6)}\n$timestamp';

  // Draw semi-transparent box
  final boxHeight = 80;
  img.fillRect(image, 0, image.height - boxHeight, image.width, image.height, img.getColor(0, 0, 0, 150));

  // Draw text
  img.drawString(image, img.arial_14, 10, image.height - boxHeight + 10, text, color: img.getColor(255, 255, 255));

  final out = await input.writeAsBytes(img.encodeJpg(image, quality: 85));
  return out;
}
