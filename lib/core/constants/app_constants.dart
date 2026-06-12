class AppConstants {
  AppConstants._();

  // ── CACHE ──
  static const Duration newsCacheTtl    = Duration(hours: 2);
  static const Duration checkCacheTtl   = Duration(minutes: 30);
  static const Duration remoteCfgFetch  = Duration(hours: 12);

  // ── PAGINATION ──
  static const int newsPageSize = 20;

  // ── STREAK RANK THRESHOLDS ──
  static const int rankObserverMin   = 7;
  static const int rankReporterMin   = 30;
  static const int rankAnalystMin    = 90;
  static const int rankGuardianMin   = 180;
  static const int rankSentinelMin   = 365;

  // ── ADMOB FREQUENCY ──
  static const int interstitialEvery          = 3;
  static const int interstitialCooldownMinutes= 5;

  // ── OSINT RATE LIMIT ──
  static const int osintDailyLimit = 3;

  // ── NEWS CATEGORIES ──
  static const List<String> newsCategories = [
    'all', 'politics', 'health', 'technology',
    'business', 'sports', 'world', 'science',
  ];

  // ── HIVE BOX NAMES ──
  static const String boxNews      = 'news_cache';
  static const String boxChecks    = 'checks_cache';
  static const String boxStreak    = 'streak_data';
  static const String boxProfile   = 'user_profile';
  static const String boxOsint     = 'osint_rate';
  static const String boxSettings  = 'settings';
  static const String boxClaimMemory = 'claim_memory';

  // ── NOTIFICATION IDs ──
  static const int notifMorning   = 1001;
  static const int notifNoon      = 1002;
  static const int notifBreaking  = 1003;
  static const int notifStreak    = 1004;

  // ── MISC ──
  static const int geminiMaxRetries = 3;
  static const int geminiTimeoutSec = 30;
  static const int maxRecentChecks  = 50;
}
