import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class AchievementBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.emoji,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   78,
      margin:  const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.bgCard
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          ColorFiltered(
            colorFilter: unlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color:    unlocked
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!unlocked)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.lock_outline_rounded,
                  color: AppColors.textMuted, size: 12),
            ),
        ],
      ),
    ).animate().fadeIn().scale(
      begin:  const Offset(0.8, 0.8),
      curve:  Curves.elasticOut,
      duration: 500.ms,
    );
  }
}
