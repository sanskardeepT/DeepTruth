import 'dart:ui';
import 'package:flutter/foundation.dart';

class LocationDetector {
  LocationDetector._();
  static final LocationDetector instance = LocationDetector._();

  String? _cachedCountry;
  String? _cachedLanguage;

  /// Returns country name derived from device locale + timezone.
  /// No GPS needed — privacy-safe.
  Future<String> getCountry() async {
    if (_cachedCountry != null) return _cachedCountry!;

    try {
      final locale   = PlatformDispatcher.instance.locale;
      final timeZone = DateTime.now().timeZoneName;

      _cachedCountry = _inferCountry(locale.countryCode, timeZone);
      return _cachedCountry!;
    } catch (e) {
      debugPrint('LocationDetector.getCountry failed: $e');
      return 'Global';
    }
  }

  Future<String> getLanguage() async {
    if (_cachedLanguage != null) return _cachedLanguage!;
    try {
      final locale = PlatformDispatcher.instance.locale;
      _cachedLanguage = locale.languageCode;
      return _cachedLanguage!;
    } catch (_) {
      return 'en';
    }
  }

  String _inferCountry(String? countryCode, String timeZone) {
    // Try country code from locale first
    if (countryCode != null) {
      const map = {
        'IN': 'India',     'US': 'United States', 'GB': 'United Kingdom',
        'AU': 'Australia', 'CA': 'Canada',         'DE': 'Germany',
        'FR': 'France',    'JP': 'Japan',          'BR': 'Brazil',
        'MX': 'Mexico',    'ZA': 'South Africa',   'NG': 'Nigeria',
        'PK': 'Pakistan',  'BD': 'Bangladesh',      'SG': 'Singapore',
      };
      final country = map[countryCode.toUpperCase()];
      if (country != null) return country;
    }

    // Fallback: timezone-based
    if (timeZone.contains('IST') || timeZone.contains('Asia/Kolkata')) {
      return 'India';
    }
    if (timeZone.contains('EST') || timeZone.contains('PST') || timeZone.contains('CST')) {
      return 'United States';
    }
    if (timeZone.contains('GMT') || timeZone.contains('BST')) {
      return 'United Kingdom';
    }
    if (timeZone.contains('AEST') || timeZone.contains('ACST')) {
      return 'Australia';
    }
    if (timeZone.contains('CET') || timeZone.contains('MEZ')) {
      return 'Germany';
    }
    return 'Global';
  }
}
