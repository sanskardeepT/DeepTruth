import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_keys.dart';
import '../constants/app_constants.dart';
import '../models/news_item.dart';
import 'gemini_service.dart';

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String _newsApiBase = 'https://newsapi.org/v2';
  static const String _gNewsBase   = 'https://gnews.io/api/v4';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // ── PUBLIC ────────────────────────────────────────────────────────
  Future<List<NewsItem>> fetchNews({
    required String country,
    required String category,
    int page = 1,
  }) async {
    final cacheKey = '${country}_${category}_$page';

    // Try cache first if not first page
    if (page > 1) {
      final cached = _readCache(cacheKey);
      if (cached != null) return cached;
    }

    List<NewsItem> articles = [];
    try {
      articles = await _fetchFromNewsApi(country, category, page);
    } catch (e) {
      debugPrint('NewsAPI failed: $e');
      try {
        articles = await _fetchFromGNews(country, category);
      } catch (e2) {
        debugPrint('GNews failed: $e2');
        articles = _getCachedNews(category);
      }
    }

    if (articles.isEmpty) {
      articles = _getOfflineMockNews(category);
    }

    // Summarize first 5 articles with Gemini
    articles = await _summarizeArticles(articles);
    _writeCache(cacheKey, articles);
    return articles;
  }

  List<NewsItem> _getOfflineMockNews(String category) {
    return [
      NewsItem(
        id: 'mock_1',
        title: 'Deepfake Videos of Public Figures Spreading Online: What You Need to Know',
        description: 'A surge in synthetic media is raising concerns about digital literacy. Experts advise checking source authenticity before sharing.',
        url: 'https://lensiq.app/education/deepfakes',
        source: 'LensIQ Trust Observatory',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: category,
        aiSummary: 'LensIQ Observatory highlights a rise in deepfakes. Users are advised to rely on verified metadata, trace sources, and avoid instant re-shares of emotionally charged clips.',
        truthScore: 85,
      ),
      NewsItem(
        id: 'mock_2',
        title: 'How to Recognize a Phishing Scam Link on WhatsApp',
        description: 'WhatsApp forwards offering free government scheme benefits are growing. Learn to identify the warning signs.',
        url: 'https://lensiq.app/education/scams',
        source: 'Cyber Security Alert',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        category: category,
        aiSummary: 'Cybersecurity agencies warn against viral forwards promising cash or prizes. Always check the domain extension and look for off-platform confirmations.',
        truthScore: 90,
      ),
    ];
  }

  // ── PRIVATE — NEWSAPI ─────────────────────────────────────────────
  Future<List<NewsItem>> _fetchFromNewsApi(
    String country,
    String category,
    int page,
  ) async {
    final countryCode = _countryToCode(country);
    final cat = category == 'all' ? 'general' : category;

    final response = await _dio.get(
      '$_newsApiBase/top-headlines',
      queryParameters: {
        'country':  countryCode,
        'category': cat,
        'pageSize': AppConstants.newsPageSize,
        'page':     page,
        'apiKey':   ApiKeys.newsApi,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('NewsAPI error: ${response.statusCode}');
    }

    final body = response.data as Map<String, dynamic>;
    final rawArticles = body['articles'] as List<dynamic>? ?? [];
    return rawArticles
        .map((a) => NewsItem.fromNewsApiJson(a as Map<String, dynamic>))
        .where((n) => n.title.isNotEmpty && n.url.isNotEmpty)
        .toList();
  }

  // ── PRIVATE — GNEWS ───────────────────────────────────────────────
  Future<List<NewsItem>> _fetchFromGNews(String country, String category) async {
    final lang = _countryToLang(country);
    final cat  = category == 'all' ? 'general' : category;

    final response = await _dio.get(
      '$_gNewsBase/top-headlines',
      queryParameters: {
        'category': cat,
        'lang':     lang,
        'max':      AppConstants.newsPageSize,
        'apikey':   ApiKeys.gNews,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('GNews error: ${response.statusCode}');
    }

    final body     = response.data as Map<String, dynamic>;
    final articles = body['articles'] as List<dynamic>? ?? [];
    return articles
        .map((a) => NewsItem.fromGNewsJson(a as Map<String, dynamic>))
        .where((n) => n.title.isNotEmpty)
        .toList();
  }

  // ── SUMMARIZE WITH GEMINI ─────────────────────────────────────────
  Future<List<NewsItem>> _summarizeArticles(List<NewsItem> articles) async {
    final toSummarize = articles.take(5).toList();
    final rest        = articles.skip(5).toList();

    final summarized = await Future.wait(
      toSummarize.map((a) async {
        try {
          final summary = await GeminiService.instance.summarizeNews(
            '${a.title}\n${a.description}',
          );
          return a.copyWith(aiSummary: summary);
        } catch (_) {
          return a;
        }
      }),
    );

    return [...summarized, ...rest];
  }

  // ── CACHE ─────────────────────────────────────────────────────────
  List<NewsItem>? _readCache(String key) {
    try {
      final box = Hive.box<String>(AppConstants.boxNews);
      final raw = box.get(key);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ts   = DateTime.tryParse(data['timestamp'] as String? ?? '');
      if (ts == null) return null;
      if (DateTime.now().difference(ts) > AppConstants.newsCacheTtl) return null;
      final list = data['articles'] as List<dynamic>;
      return list
          .map((a) => NewsItem.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  void _writeCache(String key, List<NewsItem> articles) {
    try {
      final box  = Hive.box<String>(AppConstants.boxNews);
      final data = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'articles':  articles.map((a) => a.toJson()).toList(),
      });
      box.put(key, data);
    } catch (_) {}
  }

  List<NewsItem> _getCachedNews(String category) {
    try {
      final box = Hive.box<String>(AppConstants.boxNews);
      // Return any cached news regardless of TTL as last-resort fallback
      for (final key in box.keys) {
        if (key.toString().contains(category)) {
          final raw  = box.get(key.toString());
          if (raw == null) continue;
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final list = data['articles'] as List<dynamic>;
          return list
              .map((a) => NewsItem.fromJson(a as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  String _countryToCode(String country) {
    const map = {
      'India': 'in', 'United States': 'us', 'United Kingdom': 'gb',
      'Australia': 'au', 'Canada': 'ca', 'Germany': 'de',
      'France': 'fr', 'Japan': 'jp',
    };
    return map[country] ?? 'us';
  }

  String _countryToLang(String country) {
    const map = {'India': 'hi', 'Germany': 'de', 'France': 'fr', 'Japan': 'ja'};
    return map[country] ?? 'en';
  }
}
