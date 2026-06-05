import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../utils/location_detector.dart';

/// Tracks usage patterns ONLY on-device. Never transmits data.
/// Privacy rules:
///   - Never stores raw content of checks
///   - Never stores IP address or device ID
///   - Never transmits any data remotely
class SilentProfiler {
  SilentProfiler._();
  static final SilentProfiler instance = SilentProfiler._();

  UserProfile _profile = const UserProfile(anonymousId: 'local');
  UserProfile get profile => _profile;

  List<String> get topInterests => _profile.topInterests;
  String? get inferredAgeGroup  => _profile.ageGroup;

  // ── INIT ──────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      final box = Hive.box<String>(AppConstants.boxProfile);
      final raw = box.get('profile');
      if (raw != null) {
        _profile = UserProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } else {
        // First run — detect country/language
        final country  = await LocationDetector.instance.getCountry();
        final language = await LocationDetector.instance.getLanguage();
        _profile = _profile.copyWith(country: country, language: language);
        await _persist();
      }
    } catch (e) {
      debugPrint('SilentProfiler init failed: $e');
    }
  }

  // ── TRACK CHECK ───────────────────────────────────────────────────
  Future<void> onCheckCompleted(String category) async {
    final counts = Map<String, int>.from(_profile.categoryCheckCounts);
    counts[category] = (counts[category] ?? 0) + 1;

    // Recalculate top interests (top 3 categories by count)
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topInterests = sorted.take(3).map((e) => e.key).toList();

    _profile = _profile.copyWith(
      categoryCheckCounts: counts,
      topInterests:        topInterests,
    );
    await _persist();
  }

  // ── TRACK SESSION ─────────────────────────────────────────────────
  DateTime? _sessionStart;

  void onSessionStart() => _sessionStart = DateTime.now();

  Future<void> onSessionEnd() async {
    if (_sessionStart == null) return;
    final minutes = DateTime.now().difference(_sessionStart!).inMinutes.toDouble();
    _sessionStart = null;

    final prevAvg = _profile.avgSessionMinutes;
    final newAvg  = prevAvg == 0 ? minutes : (prevAvg * 0.8 + minutes * 0.2);

    final hour       = DateTime.now().hour;
    final usageHours = List<int>.from(_profile.usageHours);
    if (!usageHours.contains(hour)) usageHours.add(hour);

    _profile = _profile.copyWith(
      avgSessionMinutes: newAvg,
      usageHours:        usageHours,
    );
    await _persist();
  }

  // ── CLEAR ALL (user-requested) ────────────────────────────────────
  Future<void> clearAllData() async {
    try {
      final box = Hive.box<String>(AppConstants.boxProfile);
      await box.clear();
      _profile = const UserProfile(anonymousId: 'local');
    } catch (e) {
      debugPrint('SilentProfiler clearAllData failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final box = Hive.box<String>(AppConstants.boxProfile);
      await box.put('profile', jsonEncode(_profile.toJson()));
    } catch (_) {}
  }
}
