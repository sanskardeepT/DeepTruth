import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/trust_verification_models.dart';

class ProvenanceEngine {
  ProvenanceEngine._();
  static final ProvenanceEngine instance = ProvenanceEngine._();

  Future<ProvenanceResult> analyzeAsset(String? filePath) async {
    try {
      if (filePath == null) {
        return const ProvenanceResult(reusedCount: 0);
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return const ProvenanceResult(reusedCount: 0);
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      String? cameraMake;
      String? cameraModel;
      String? software;
      String? dateTime;
      String? gpsInfo;
      final exifTags = <String, String>{};

      if (image != null && image.exif != null) {
        final exif = image.exif;
        if (exif.imageIfd.containsKey(0x010f)) {
          cameraMake = exif.imageIfd[0x010f]?.toString().trim();
          exifTags['Make'] = cameraMake ?? '';
        }
        if (exif.imageIfd.containsKey(0x0110)) {
          cameraModel = exif.imageIfd[0x0110]?.toString().trim();
          exifTags['Model'] = cameraModel ?? '';
        }
        if (exif.imageIfd.containsKey(0x0131)) {
          software = exif.imageIfd[0x0131]?.toString().trim();
          exifTags['Software'] = software ?? '';
        }
        if (exif.imageIfd.containsKey(0x0132)) {
          dateTime = exif.imageIfd[0x0132]?.toString().trim();
          exifTags['DateTime'] = dateTime ?? '';
        }
        if (!exif.gpsIfd.isEmpty) {
          gpsInfo = 'GPS Coordinates present 📍';
          exifTags['GPSInfo'] = gpsInfo;
        }
      }

      return ProvenanceResult(
        firstAppearance: dateTime,
        sourceDomain: null,
        creator: null,
        reusedCount: 0,
        earliestDate: dateTime,
        exif: exifTags,
        gps: gpsInfo,
        camera: cameraModel ?? cameraMake,
        software: software,
      );
    } catch (e) {
      debugPrint('ProvenanceEngine error: $e');
      return const ProvenanceResult(reusedCount: 0);
    }
  }
}
