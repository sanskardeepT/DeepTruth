import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashUtil {
  HashUtil._();

  /// Calculates SHA-256 of the given bytes.
  static String calculateSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
