import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';
import '../../../widgets/loading_shimmer.dart';

class TrendingChecksList extends StatelessWidget {
  const TrendingChecksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'TRENDING CHECKS',
            style: TextStyle(
              color:        AppColors.textMuted,
              fontSize:     11,
              fontWeight:   FontWeight.bold,
              letterSpacing:1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AppProvider>(
          builder: (_, app, __) {
            if (!app.isInitialized) {
              return const ListShimmer(count: 3);
            }
            if (app.trendingChecks.isEmpty) {
              return const SizedBox.shrink();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: app.trendingChecks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = app.trendingChecks[i];
                return _TrendingItem(
                  topic: item['topic'] as String? ?? '',
                  count: (item['checkCount'] as num?)?.toInt() ?? 0,
                  index: i,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final String topic;
  final int count;
  final int index;

  const _TrendingItem({
    required this.topic,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:  AppColors.accent.withValues(alpha: 0.1),
              shape:  BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color:      AppColors.accent,
                fontSize:   12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topic,
              style: const TextStyle(
                color:    AppColors.textPrimary,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_formatCount(count)} checks',
              style: const TextStyle(
                color:    AppColors.danger,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.2);
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
