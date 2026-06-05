import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseFirestore? _firestore;
  FirebaseAnalytics? _analytics;
  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      _firestore    = FirebaseFirestore.instance;
      _analytics    = FirebaseAnalytics.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setDefaults({
        'show_ads':           true,
        'interstitial_every': 3,
        'daily_fact_enabled': true,
      });
      await _remoteConfig!.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      debugPrint('Firebase service init failed: $e');
    }
  }

  // ── TRENDING CHECKS ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTrendingChecks() async {
    if (!_initialized || _firestore == null) return _fallbackTrending();
    try {
      final snapshot = await _firestore!
          .collection('trending_checks')
          .orderBy('checkCount', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('getTrendingChecks failed: $e');
      return _fallbackTrending();
    }
  }

  // ── DAILY REALITY ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getDailyReality() async {
    if (!_initialized || _firestore == null) return _fallbackDailyReality();
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final doc   = await _firestore!
          .collection('daily_reality')
          .doc(today)
          .get();
      return doc.exists ? doc.data() : _fallbackDailyReality();
    } catch (e) {
      debugPrint('getDailyReality failed: $e');
      return _fallbackDailyReality();
    }
  }

  // ── LEADERBOARD ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    if (!_initialized || _firestore == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('leaderboard')
          .orderBy('streakDays', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('getLeaderboard failed: $e');
      return [];
    }
  }

  Future<void> updateLeaderboard({
    required String anonymousId,
    required String displayName,
    required int streakDays,
    required String rank,
    required String country,
  }) async {
    if (!_initialized || _firestore == null) return;
    try {
      await _firestore!.collection('leaderboard').doc(anonymousId).set({
        'displayName': displayName,
        'streakDays':  streakDays,
        'rank':        rank,
        'country':     country,
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('updateLeaderboard failed: $e');
    }
  }

  // ── ANALYTICS ─────────────────────────────────────────────────────
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  Future<void> logFactCheck(String verdict, int score) async {
    await logEvent('fact_check', {'verdict': verdict, 'score': score});
  }

  Future<void> logScreenView(String screenName) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // ── CRASHLYTICS ───────────────────────────────────────────────────
  Future<void> recordError(dynamic error, StackTrace? stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack);
    } catch (_) {}
  }

  // ── REMOTE CONFIG ─────────────────────────────────────────────────
  bool get showAds {
    try {
      return _remoteConfig?.getBool('show_ads') ?? true;
    } catch (_) {
      return true;
    }
  }

  bool get dailyFactEnabled {
    try {
      return _remoteConfig?.getBool('daily_fact_enabled') ?? true;
    } catch (_) {
      return true;
    }
  }

  // ── FALLBACKS ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _fallbackTrending() => [
    {'topic': 'Viral health claim circulating on WhatsApp', 'checkCount': 1240},
    {'topic': 'Government scheme announced — real or fake?', 'checkCount': 890},
    {'topic': 'Stock market prediction going viral', 'checkCount': 750},
    {'topic': 'Celebrity quote shared out of context', 'checkCount': 620},
    {'topic': 'Weather/disaster warning spreading on social media', 'checkCount': 480},
  ];

  Map<String, dynamic> _fallbackDailyReality() => {
    'fact':      'More than 500 million pieces of misinformation are shared online every single day.',
    'source':    'Reuters Institute Digital News Report',
    'sourceUrl': 'https://reutersinstitute.politics.ox.ac.uk',
    'category':  'Media Literacy',
  };
}
