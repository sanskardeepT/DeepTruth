import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();

  /// Reads a cached value. Returns null if missing or expired.
  T? read<T>({
    required String boxName,
    required String key,
    required Duration ttl,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    try {
      final box = Hive.box<String>(boxName);
      final raw = box.get(key);
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ts   = DateTime.tryParse(data['_ts'] as String? ?? '');
      if (ts == null) return null;
      if (DateTime.now().difference(ts) > ttl) return null;

      return fromJson(data['value'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Reads a cached list. Returns null if missing or expired.
  List<T>? readList<T>({
    required String boxName,
    required String key,
    required Duration ttl,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    try {
      final box = Hive.box<String>(boxName);
      final raw = box.get(key);
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ts   = DateTime.tryParse(data['_ts'] as String? ?? '');
      if (ts == null) return null;
      if (DateTime.now().difference(ts) > ttl) return null;

      final list = data['value'] as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Writes a value to cache with timestamp.
  Future<void> write({
    required String boxName,
    required String key,
    required Map<String, dynamic> value,
  }) async {
    try {
      final box  = Hive.box<String>(boxName);
      final data = jsonEncode({
        '_ts':   DateTime.now().toIso8601String(),
        'value': value,
      });
      await box.put(key, data);
    } catch (_) {}
  }

  /// Writes a list to cache with timestamp.
  Future<void> writeList({
    required String boxName,
    required String key,
    required List<Map<String, dynamic>> value,
  }) async {
    try {
      final box  = Hive.box<String>(boxName);
      final data = jsonEncode({
        '_ts':   DateTime.now().toIso8601String(),
        'value': value,
      });
      await box.put(key, data);
    } catch (_) {}
  }

  Future<void> delete({required String boxName, required String key}) async {
    try {
      final box = Hive.box<String>(boxName);
      await box.delete(key);
    } catch (_) {}
  }

  Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box<String>(boxName);
      await box.clear();
    } catch (_) {}
  }
}
