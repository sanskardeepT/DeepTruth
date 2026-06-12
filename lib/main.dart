import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/services/admob_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/silent_profiler.dart';
import 'app.dart';

Future<void> main() async {
  // 1. Binding first — always
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Hive (local storage) — before any service reads prefs
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(AppConstants.boxNews),
    Hive.openBox<String>(AppConstants.boxChecks),
    Hive.openBox<String>(AppConstants.boxStreak),
    Hive.openBox<String>(AppConstants.boxProfile),
    Hive.openBox<String>(AppConstants.boxOsint),
    Hive.openBox<String>(AppConstants.boxSettings),
    Hive.openBox<String>(AppConstants.boxClaimMemory),
    Hive.openBox<String>(AppConstants.boxReputationHistory),
  ]);

  // 4. Firebase — graceful failure allowed
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init failed (offline mode): $e');
  }

  // 5. AdMob — graceful failure allowed
  try {
    await MobileAds.instance.initialize();
    AdMobService.instance.preloadInterstitial();
    AdMobService.instance.preloadRewardedAd();
  } catch (e) {
    debugPrint('AdMob init failed: $e');
  }

  // 6. Gemini service
  GeminiService.instance.initialize();

  // 7. Silent profiler
  await SilentProfiler.instance.initialize();

  // 8. Notifications (request permission on first run)
  await NotificationService.instance.initialize();

  runApp(const DeepTruthApp());
}
