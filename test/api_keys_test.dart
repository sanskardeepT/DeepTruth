import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:deeptruth/core/constants/api_keys.dart';
import 'package:deeptruth/core/constants/app_constants.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('deeptruth_api_keys_test_hive');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(AppConstants.boxSettings);
  });

  tearDown(() async {
    await Hive.close();
  });

  test('ApiKeys fallback to default values when no custom keys are stored', () {
    expect(ApiKeys.gemini, equals('YOUR_GEMINI_API_KEY'));
    expect(ApiKeys.newsApi, equals('YOUR_NEWS_API_KEY'));
    expect(ApiKeys.gNews, equals('YOUR_GNEWS_API_KEY'));
    expect(ApiKeys.googleFactCheck, equals('YOUR_FACT_CHECK_API_KEY'));
    expect(ApiKeys.hibp, equals('YOUR_HIBP_API_KEY'));
  });

  test('ApiKeys load custom keys from Hive when box contains values', () async {
    final box = Hive.box<String>(AppConstants.boxSettings);
    await box.put('custom_key_gemini', 'my-custom-gemini-key');
    await box.put('custom_key_news_api', 'my-custom-news-key');
    await box.put('custom_key_g_news', 'my-custom-gnews-key');
    await box.put('custom_key_google_fact_check', 'my-custom-fact-check-key');
    await box.put('custom_key_hibp', 'my-custom-hibp-key');

    expect(ApiKeys.gemini, equals('my-custom-gemini-key'));
    expect(ApiKeys.newsApi, equals('my-custom-news-key'));
    expect(ApiKeys.gNews, equals('my-custom-gnews-key'));
    expect(ApiKeys.googleFactCheck, equals('my-custom-fact-check-key'));
    expect(ApiKeys.hibp, equals('my-custom-hibp-key'));
  });

  test('ApiKeys ignore invalid/placeholder values and fall back', () async {
    final box = Hive.box<String>(AppConstants.boxSettings);
    await box.put('custom_key_gemini', 'YOUR_GEMINI_API_KEY'); // Should ignore and fallback
    await box.put('custom_key_news_api', '  '); // Should ignore and fallback

    expect(ApiKeys.gemini, equals('YOUR_GEMINI_API_KEY'));
    expect(ApiKeys.newsApi, equals('YOUR_NEWS_API_KEY'));
  });
}
