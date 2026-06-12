import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';
import '../utils/location_detector.dart';
import '../utils/silent_profiler.dart';

import '../services/streak_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isInitialized = false;
  String _country = 'Global';
  Map<String, dynamic>? _dailyReality;
  List<Map<String, dynamic>> _trendingChecks = [];
  Locale _locale = const Locale('en');

  bool get isOnline      => _isOnline;
  bool get isInitialized => _isInitialized;
  String get country     => _country;
  Map<String, dynamic>? get dailyReality  => _dailyReality;
  List<Map<String, dynamic>> get trendingChecks => _trendingChecks;
  Locale get locale => _locale;

  late final Connectivity _connectivity;

  AppProvider() {
    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _loadLocale();
  }

  void _loadLocale() {
    try {
      final box = Hive.box<String>(AppConstants.boxSettings);
      final langCode = box.get('language_code', defaultValue: 'en');
      _locale = Locale(langCode ?? 'en');
    } catch (_) {}
  }

  Future<void> changeLocale(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'hi') return;
    _locale = Locale(languageCode);
    try {
      final box = Hive.box<String>(AppConstants.boxSettings);
      await box.put('language_code', languageCode);
    } catch (_) {}
    notifyListeners();
  }

  AppProvider.test() {
    _isOnline = true;
    _country = 'Global';
    _isInitialized = true;
  }

  Future<void> initialize() async {
    try {
      // Check connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;

      // Detect country
      _country = await LocationDetector.instance.getCountry();

      // Load Firebase data
      _dailyReality  = await FirebaseService.instance.getDailyReality();
      _trendingChecks = await FirebaseService.instance.getTrendingChecks();

      // Track session in Firestore DAU/WAU
      try {
        await FirebaseService.instance.trackUserSession(StreakService.instance.anonymousId);
      } catch (_) {}

      // Start profiler session
      SilentProfiler.instance.onSessionStart();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider.initialize failed: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> refreshHomeData() async {
    try {
      _dailyReality   = await FirebaseService.instance.getDailyReality();
      _trendingChecks = await FirebaseService.instance.getTrendingChecks();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> checkMaintenanceStatus() async {
    try {
      await FirebaseService.instance.initialize();
      notifyListeners();
    } catch (_) {}
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    if (wasOnline != _isOnline) notifyListeners();
  }

  @override
  void dispose() {
    SilentProfiler.instance.onSessionEnd();
    super.dispose();
  }
}
