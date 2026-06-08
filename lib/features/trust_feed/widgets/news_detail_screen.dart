import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/news_item.dart';
import '../../../core/providers/check_provider.dart';
import '../../../widgets/ad_banner_widget.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMeta(context),
                const SizedBox(height: 16),
                _buildSummary(context),
                const SizedBox(height: 20),
                _buildFactCheckCta(context),
                const SizedBox(height: 24),
                _buildReadOriginalButton(context),
                const SizedBox(height: 16),
                const AdBannerWidget(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: article.imageUrl != null ? 240 : 0,
      pinned: true,
      backgroundColor: AppColors.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary),
          onPressed: () => Share.share(
            '${article.title}\n\n${article.url}\n\nVerified by DeepTruth',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.textSecondary),
          onPressed: () => _launchUrl(article.url),
        ),
      ],
      flexibleSpace: article.imageUrl != null
          ? FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: article.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppColors.bgSecondary),
              ),
            )
          : null,
    );
  }

  Widget _buildMeta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.source.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              article.source,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          article.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        Text(
          _formatDate(article.publishedAt),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    if (article.aiSummary == null || article.aiSummary!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text(
                'AI Summary',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            article.aiSummary!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFactCheckCta(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Pre-fill TruthLens with this article's title for fact-checking
        final checkProvider = context.read<CheckProvider>();
        checkProvider.prefillContent(article.title);
        Navigator.of(context).pop();
        // Navigate to TruthLens tab (index 1)
        final shell = context.findAncestorStateOfType<MainShellState>();
        shell?.setIndex(1);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.policy_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fact-check this article',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Get a full Truth Score with verified sources',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildReadOriginalButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _launchUrl(article.url),
      icon: const Icon(Icons.open_in_new_rounded, size: 18),
      label: const Text('Read original article'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
