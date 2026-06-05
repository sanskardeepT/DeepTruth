import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/news_item.dart';

class NewsCard extends StatelessWidget {
  final NewsItem article;
  final int index;

  const NewsCard({super.key, required this.article, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openArticle(article.url),
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
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl:   article.imageUrl!,
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
                          color:        AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source,
                          style: const TextStyle(
                            color:    AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(article.publishedAt),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    article.title,
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
                    article.aiSummary ?? article.description,
                    style: const TextStyle(
                      color:   AppColors.textSecondary,
                      fontSize:12,
                      height:  1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.aiSummary != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accent, size: 11),
                        const SizedBox(width: 4),
                        const Text(
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
      ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1),
    );
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
