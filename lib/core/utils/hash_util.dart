import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class HashUtil {
  HashUtil._();

  /// Calculates SHA-256 of the given bytes synchronously on the current thread.
  static String calculateSha256Sync(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Calculates SHA-256 of the given bytes in a background isolate using compute.
  static Future<String> calculateSha256(Uint8List bytes) async {
    // Run hashing logic inside a separate isolate
    return compute(_hashIsolate, bytes);
  }

  static String _hashIsolate(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
