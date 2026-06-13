// lib/core/constants/api_keys.dart — DeepTruth API Configuration
// IMPORTANT: Add this file to .gitignore before committing

import 'package:hive/hive.dart';
import 'app_constants.dart';

class ApiKeys {
  ApiKeys._();

  static String _getKey(String name, String defaultValue) {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        final val = box.get('custom_key_$name');
        if (val != null && val.trim().isNotEmpty && !val.contains('YOUR_')) {
          return val.trim();
        }
      }
    } catch (_) {}
    return defaultValue;
  }

  // ── GEMINI AI ─────────────────────────────────────────
  static String get gemini => _getKey('gemini', 'YOUR_GEMINI_API_KEY');

  // ── NEWS ──────────────────────────────────────────────
  static String get newsApi => _getKey('news_api', 'YOUR_NEWS_API_KEY');
  static String get gNews  => _getKey('g_news', 'YOUR_GNEWS_API_KEY');

  // ── FACT CHECK ────────────────────────────────────────
  static String get googleFactCheck => _getKey('google_fact_check', 'YOUR_FACT_CHECK_API_KEY');
  static String get googleCseKey => _getKey('google_cse_key', 'YOUR_GOOGLE_CSE_KEY');
  static String get googleCseId => _getKey('google_cse_cx', 'YOUR_GOOGLE_CSE_CX');

  // ── OSINT ─────────────────────────────────────────────
  static String get hibp => _getKey('hibp', 'YOUR_HIBP_API_KEY');

  // ── THREAT INTEL ───────────────────────────────────────
  static String get virusTotal => _getKey('virus_total', 'YOUR_VIRUSTOTAL_API_KEY');
  static String get urlscan    => _getKey('urlscan', 'YOUR_URLSCAN_API_KEY');

  // ── ADMOB ─────────────────────────────────────────────
  static const String _testAppId          = 'ca-app-pub-3940256099942544~3347511713';
  static const String _testBannerId       = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId     = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNativeId       = 'ca-app-pub-3940256099942544/2247696110';

  static const String _prodAppId          = 'YOUR_REAL_ADMOB_APP_ID';
  static const String _prodBannerId       = 'YOUR_REAL_BANNER_ID';
  static const String _prodInterstitialId = 'YOUR_REAL_INTERSTITIAL_ID';
  static const String _prodRewardedId     = 'YOUR_REAL_REWARDED_ID';
  static const String _prodNativeId       = 'YOUR_REAL_NATIVE_ID';

  static bool get _isRelease => const bool.fromEnvironment('dart.vm.product');

  static String get adMobAppId           => _isRelease ? _prodAppId : _testAppId;
  static String get bannerAdUnitId       => _isRelease ? _prodBannerId : _testBannerId;
  static String get interstitialAdUnitId => _isRelease ? _prodInterstitialId : _testInterstitialId;
  static String get rewardedAdUnitId     => _isRelease ? _prodRewardedId : _testRewardedId;
  static String get nativeAdUnitId       => _isRelease ? _prodNativeId : _testNativeId;

  // ── KEY VALIDATION GUARDS ──────────────────────────────────────
  /// Returns true if the given key is a real configured key (not a placeholder).
  static bool isKeyConfigured(String key) =>
      key.isNotEmpty && !key.startsWith('YOUR_');

  /// Returns true if AdMob IDs are configured for the current build mode.
  /// In debug mode, test IDs are always valid.
  /// In release mode, rejects the `YOUR_REAL_` placeholder.
  static bool get isAdMobConfigured =>
      !_isRelease || !_prodAppId.startsWith('YOUR_');
}
