import 'package:flutter_test/flutter_test.dart';
import 'package:deeptruth/core/services/firebase_service.dart';
import 'package:deeptruth/core/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Founder Operations Layer Test', () {
    test('Firebase Service admin analytics fallback', () async {
      // Firestore/Firebase is not initialized in normal unit test context
      // The service must return fallback/mock metrics safely instead of throwing exceptions
      final analytics = await FirebaseService.instance.getAdminAnalytics();
      expect(analytics, isNotNull);
      expect(analytics.containsKey('totalUsers'), isTrue);
      expect(analytics.containsKey('dau'), isTrue);
      expect(analytics.containsKey('totalScans'), isTrue);
      expect(analytics.containsKey('revenue'), isTrue);
      expect(analytics.containsKey('mostUsedFeatures'), isTrue);
    });

    test('Firebase Service announcements fallback', () async {
      final announcements = await FirebaseService.instance.getAnnouncements();
      expect(announcements, isEmpty); // Empty when firestore is not initialized
    });

    test('App Provider checkMaintenanceStatus executes gracefully', () async {
      final provider = AppProvider.test();
      await provider.checkMaintenanceStatus();
      expect(provider.isInitialized, isTrue);
    });
  });
}
