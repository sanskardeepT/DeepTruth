import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/news_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/loading_shimmer.dart';
import 'widgets/news_card.dart';
import 'widgets/category_tab_bar.dart';

class TrustFeedScreen extends StatefulWidget {
  const TrustFeedScreen({super.key});

  @override
  State<TrustFeedScreen> createState() => _TrustFeedScreenState();
}

class _TrustFeedScreenState extends State<TrustFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _loadInitial() {
    final country  = context.read<AppProvider>().country;
    final news     = context.read<NewsProvider>();
    final category = news.activeCategory;
    if (news.getArticles(category).isEmpty) {
      news.fetchCategory(category, country);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final news    = context.read<NewsProvider>();
      final country = context.read<AppProvider>().country;
      news.loadMore(news.activeCategory, country);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.feedTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: CategoryTabBar(
            onCategoryChanged: (cat) {
              final country = context.read<AppProvider>().country;
              context.read<NewsProvider>()
                ..setActiveCategory(cat)
                ..fetchCategory(cat, country);
            },
          ),
        ),
      ),
      body: Consumer2<NewsProvider, AppProvider>(
        builder: (_, news, app, __) {
          final category = news.activeCategory;
          final articles = news.getArticles(category);
          final loading  = news.isLoading(category);
          final error    = news.getError(category);

          if (loading && articles.isEmpty) {
            return Column(children: [
              Expanded(child: ListShimmer(count: 5)),
              const AdBannerWidget(),
            ]);
          }

          if (error != null && articles.isEmpty) {
            return Column(children: [
              Expanded(child: AppErrorWidget(
                message: error,
                onRetry: () => news.fetchCategory(category, app.country),
              )),
              const AdBannerWidget(),
            ]);
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color:           AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => news.refresh(category, app.country),
                  child: ListView.builder(
                    controller:  _scrollController,
                    itemCount:   articles.length + 1,
                    itemBuilder: (ctx, i) {
                      // Insert native ad every 5 items
                      if (i > 0 && i % 5 == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: _NativeAdPlaceholder(),
                        );
                      }
                      final idx = i - (i ~/ 5);
                      if (idx >= articles.length) {
                        return loading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 80);
                      }
                      return NewsCard(
                        article: articles[idx],
                        index:   idx,
                      );
                    },
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          );
        },
      ),
    );
  }
}

class _NativeAdPlaceholder extends StatelessWidget {
  const _NativeAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width:  48,
            height: 48,
            color: AppColors.divider,
            child: const Icon(Icons.campaign_outlined, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sponsored', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                SizedBox(height: 4),
                Text('Ad content loads here', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
