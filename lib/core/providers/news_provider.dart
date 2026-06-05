import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../utils/error_handler.dart';

class NewsProvider extends ChangeNotifier {
  final Map<String, List<NewsItem>> _articles = {};
  final Map<String, bool> _loadingMap  = {};
  final Map<String, String?> _errorMap = {};
  final Map<String, int> _pageMap      = {};

  String _activeCategory = 'all';
  String get activeCategory => _activeCategory;

  List<NewsItem> getArticles(String category) => _articles[category] ?? [];
  bool isLoading(String category)    => _loadingMap[category] ?? false;
  String? getError(String category)  => _errorMap[category];
  bool hasMore(String category)      => (_articles[category]?.length ?? 0) % 20 == 0;

  Future<void> fetchCategory(String category, String country) async {
    if (_loadingMap[category] == true) return;

    _loadingMap[category] = true;
    _errorMap[category]   = null;
    _pageMap[category]    = 1;
    notifyListeners();

    try {
      final articles = await NewsService.instance.fetchNews(
        country:  country,
        category: category,
        page:     1,
      );
      _articles[category] = articles;
    } catch (e) {
      _errorMap[category] = ErrorHandler.toUserMessage(e);
    } finally {
      _loadingMap[category] = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(String category, String country) async {
    if (_loadingMap[category] == true) return;
    final nextPage = (_pageMap[category] ?? 1) + 1;

    _loadingMap[category] = true;
    notifyListeners();

    try {
      final more = await NewsService.instance.fetchNews(
        country:  country,
        category: category,
        page:     nextPage,
      );
      _articles[category] = [...(_articles[category] ?? []), ...more];
      _pageMap[category]  = nextPage;
    } catch (_) {
      // Silently fail — existing articles stay
    } finally {
      _loadingMap[category] = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String category, String country) async {
    _articles.remove(category);
    await fetchCategory(category, country);
  }

  void setActiveCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }
}
