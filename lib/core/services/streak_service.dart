import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../models/streak_data.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const _uuid = Uuid();

  StreakData _current = const StreakData();
  StreakData get current => _current;

  List<int> _recentScores = [];
  List<int> get recentScores => _recentScores;

  String? _anonymousId;
  String get anonymousId {
    _anonymousId ??= _loadOrCreateAnonymousId();
    return _anonymousId!;
  }

  // ── INIT ──────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      final box = Hive.box<String>(AppConstants.boxStreak);
      final raw = box.get('streak');
      if (raw != null) {
        _current = StreakData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
      final scoresRaw = box.get('recent_scores');
      if (scoresRaw != null) {
        _recentScores = List<int>.from(jsonDecode(scoresRaw) as List);
      }
    } catch (e) {
      debugPrint('StreakService init failed: $e');
    }
  }

  // ── RECORD DAILY OPEN ─────────────────────────────────────────────
  Future<StreakData> recordDailyOpen() async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_current.lastActiveDate != null) {
      final last = DateTime(
        _current.lastActiveDate!.year,
        _current.lastActiveDate!.month,
        _current.lastActiveDate!.day,
      );

      if (last == today) return _current; // Already recorded today

      final diff = today.difference(last).inDays;
      if (diff == 1) {
        // Consecutive day
        _current = _current.copyWith(
          currentStreak:  _current.currentStreak + 1,
          longestStreak:  _current.currentStreak + 1 > _current.longestStreak
              ? _current.currentStreak + 1
              : _current.longestStreak,
          lastActiveDate: now,
        );
      } else {
        // Streak broken
        _current = _current.copyWith(
          currentStreak:  1,
          lastActiveDate: now,
        );
      }
    } else {
      _current = _current.copyWith(
        currentStreak:  1,
        longestStreak:  1,
        lastActiveDate: now,
      );
    }

    await _persist();
    await _syncLeaderboard();

    if (_current.isStreakAtRisk) {
      await NotificationService.instance.scheduleStreakReminder(_current.currentStreak);
    }

    return _current;
  }

  // ── RECORD CHECK COMPLETED ────────────────────────────────────────
  Future<void> recordCheckCompleted({bool wasFake = false, int? truthScore}) async {
    _current = _current.copyWith(
      totalChecks: _current.totalChecks + 1,
      fakesCaught: wasFake ? _current.fakesCaught + 1 : null,
    );
    if (truthScore != null) {
      _recentScores.add(truthScore);
      if (_recentScores.length > 7) {
        _recentScores.removeAt(0);
      }
      try {
        final box = Hive.box<String>(AppConstants.boxStreak);
        await box.put('recent_scores', jsonEncode(_recentScores));
      } catch (_) {}
    }
    await _persist();
  }

  // ── FREEZE STREAK ─────────────────────────────────────────────────
  Future<bool> freezeStreak() async {
    if (!_current.canFreeze) return false;

    final now = DateTime.now();
    _current = _current.copyWith(
      lastActiveDate:       now, // Reset the clock
      freezesUsedThisMonth: _current.freezesUsedThisMonth + 1,
      lastFreezeDate:       now,
    );
    await _persist();
    return true;
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  Future<void> _persist() async {
    try {
      final box = Hive.box<String>(AppConstants.boxStreak);
      await box.put('streak', jsonEncode(_current.toJson()));
    } catch (e) {
      debugPrint('Streak persist failed: $e');
    }
  }

  Future<void> _syncLeaderboard() async {
    try {
      await FirebaseService.instance.updateLeaderboard(
        anonymousId: anonymousId,
        displayName: 'User#${anonymousId.substring(0, 4).toUpperCase()}',
        streakDays:  _current.currentStreak,
        rank:        _current.rank,
        country:     'Global',
      );
    } catch (_) {}
  }

  String _loadOrCreateAnonymousId() {
    try {
      final box = Hive.box<String>(AppConstants.boxSettings);
      final id  = box.get('anonymous_id');
      if (id != null) return id;
      final newId = _uuid.v4();
      box.put('anonymous_id', newId);
      return newId;
    } catch (_) {
      return _uuid.v4();
    }
  }
}
