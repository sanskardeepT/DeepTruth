import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/streak_data.dart';

class RankProgressCard extends StatelessWidget {
  final StreakData streak;

  const RankProgressCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final progress = streak.currentStreak / streak.nextRankThreshold;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RANK PROGRESS',
                style: TextStyle(
                  color:        AppColors.textMuted,
                  fontSize:     10,
                  fontWeight:   FontWeight.bold,
                  letterSpacing:1.2,
                ),
              ),
              Text(
                '${streak.currentStreak} / ${streak.nextRankThreshold} days',
                style: const TextStyle(
                    color: AppColors.accent, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:           clampedProgress,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight:       8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                streak.rank,
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize:   13,
                ),
              ),
              Text(
                streak.currentStreak >= streak.nextRankThreshold
                    ? 'MAX RANK! 🎉'
                    : '${streak.nextRankThreshold - streak.currentStreak} days to next rank',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}
