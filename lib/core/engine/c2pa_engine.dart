import 'dart:io';
import 'dart:typed_data';
import '../models/trust_verification_models.dart';

class C2paEngine {
  C2paEngine._();
  static final C2paEngine instance = C2paEngine._();

  Future<C2PAResult> verifyAsset(String? filePath, [Uint8List? fileBytes]) async {
    try {
      Uint8List? bytes = fileBytes;
      if (bytes == null && filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        return const C2PAResult(
          hasC2PA: false,
          trustScore: 0,
          verificationStatus: 'NO_ASSET_DATA',
        );
      }

      // Check if file contains C2PA signature tags ("c2pa" or "jumb")
      bool hasC2PAMarker = false;
      final c2paMarker = 'c2pa'.codeUnits;
      final jumbMarker = 'jumb'.codeUnits;

      for (int i = 0; i < bytes.length - 4; i++) {
        if ((bytes[i] == c2paMarker[0] &&
                bytes[i + 1] == c2paMarker[1] &&
                bytes[i + 2] == c2paMarker[2] &&
                bytes[i + 3] == c2paMarker[3]) ||
            (bytes[i] == jumbMarker[0] &&
                bytes[i + 1] == jumbMarker[1] &&
                bytes[i + 2] == jumbMarker[2] &&
                bytes[i + 3] == jumbMarker[3])) {
          hasC2PAMarker = true;
          break;
        }
      }

      if (hasC2PAMarker) {
        return const C2PAResult(
          hasC2PA: true,
          creator: null,
          publisher: null,
          createdAt: null,
          editedBy: [],
          trustScore: 75,
          verificationStatus: 'C2PA_SIGNATURE_PRESENT',
        );
      }

      return const C2PAResult(
        hasC2PA: false,
        trustScore: 0,
        verificationStatus: 'UNSIGNED_MEDIA',
      );
    } catch (e) {
      return C2PAResult(
        hasC2PA: false,
        trustScore: 0,
        verificationStatus: 'VERIFICATION_FAILED: $e',
      );
    }
  }
}
