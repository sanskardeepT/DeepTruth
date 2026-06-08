import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:deeptruth/app.dart';
import 'package:deeptruth/core/providers/app_provider.dart';
import 'package:deeptruth/core/providers/check_provider.dart';
import 'package:deeptruth/core/providers/news_provider.dart';
import 'package:deeptruth/core/providers/streak_provider.dart';
import 'package:deeptruth/core/models/news_item.dart';
import 'package:deeptruth/core/constants/app_constants.dart';

class TestNewsProvider extends NewsProvider {
  @override
  List<NewsItem> getArticles(String category) => [
        NewsItem(
          id: '1',
          title: 'Test Title',
          description: 'Test Description',
          url: 'https://test.com',
          imageUrl: 'https://test.com/image.png',
          publishedAt: DateTime.now(),
          source: 'Test Source',
          category: 'general',
          aiSummary: 'Test AI Summary',
        ),
      ];

  @override
  Future<void> fetchCategory(String category, String country) async {
    // Do nothing in test
  }
}

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('deeptruth_test_hive');
    Hive.init(tempDir.path);
    await Future.wait([
      Hive.openBox<String>(AppConstants.boxNews),
      Hive.openBox<String>(AppConstants.boxChecks),
      Hive.openBox<String>(AppConstants.boxStreak),
      Hive.openBox<String>(AppConstants.boxProfile),
      Hive.openBox<String>(AppConstants.boxOsint),
      Hive.openBox<String>(AppConstants.boxSettings),
    ]);
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('DeepTruthApp builds and shows Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider.test()),
          ChangeNotifierProvider(create: (_) => CheckProvider()),
          ChangeNotifierProvider<NewsProvider>(create: (_) => TestNewsProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );

    // Pump to render and advance time to exhaust delayed animation timers
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify navigation bar shows Home
    expect(find.text('Home'), findsWidgets);
  });
}
