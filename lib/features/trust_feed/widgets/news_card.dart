import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/news_item.dart';
import 'news_detail_screen.dart';

class NewsCard extends StatefulWidget {
  final NewsItem article;
  final int index;

  const NewsCard({super.key, required this.article, required this.index});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        _isBookmarked = box.get('bookmark_${widget.article.id}') != null;
      }
    } catch (_) {}
  }

  void _toggleBookmark() {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        final key = 'bookmark_${widget.article.id}';
        if (_isBookmarked) {
          box.delete(key);
        } else {
          box.put(key, widget.article.title);
        }
        if (mounted) setState(() => _isBookmarked = !_isBookmarked);
      }
    } catch (_) {}
  }

  void _shareArticle() {
    Share.share(
      '${widget.article.title}\n\n${widget.article.url}\n\nShared via DeepTruth',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(article: widget.article),
        ),
      ),
      child: Container(
        margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (widget.article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl:   widget.article.imageUrl!,
                  height:     180,
                  width:      double.infinity,
                  fit:        BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color:  AppColors.bgSecondary,
                    child:  const Icon(Icons.image_outlined,
                        color: AppColors.textMuted, size: 40),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color:  AppColors.bgSecondary,
                    child:  const Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.article.source,
                          style: const TextStyle(
                            color:    AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(widget.article.publishedAt),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                      const Spacer(),
                      // Share button
                      GestureDetector(
                        onTap: _shareArticle,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.share_outlined,
                              color: AppColors.textMuted, size: 16),
                        ),
                      ),
                      // Bookmark button
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isBookmarked
                                ? AppColors.accent
                                : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      color:      AppColors.textPrimary,
                      fontSize:   15,
                      fontWeight: FontWeight.w600,
                      height:     1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // AI summary or description
                  Text(
                    widget.article.aiSummary ?? widget.article.description,
                    style: const TextStyle(
                      color:   AppColors.textSecondary,
                      fontSize:12,
                      height:  1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.article.aiSummary != null) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accent, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'AI Summary',
                          style: TextStyle(
                              color: AppColors.accent, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: (widget.index * 50).ms).fadeIn().slideY(begin: 0.1),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

