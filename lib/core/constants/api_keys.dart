// lib/core/constants/api_keys.dart
// IMPORTANT: Add this file to .gitignore before committing

class ApiKeys {
  ApiKeys._();

  // ── GEMINI AI ─────────────────────────────────────────
  static const String gemini = 'YOUR_GEMINI_API_KEY';

  // ── NEWS ──────────────────────────────────────────────
  static const String newsApi = 'YOUR_NEWS_API_KEY';
  static const String gNews  = 'YOUR_GNEWS_API_KEY';

  // ── FACT CHECK ────────────────────────────────────────
  static const String googleFactCheck = 'YOUR_FACT_CHECK_API_KEY';

  // ── OSINT ─────────────────────────────────────────────
  static const String hibp = 'YOUR_HIBP_API_KEY';

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
}
