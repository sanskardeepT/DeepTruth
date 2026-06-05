import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';

class DailyRealityCard extends StatelessWidget {
  const DailyRealityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, app, __) {
        final data = app.dailyReality;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1535), Color(0xFF1A2050)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color:       AppColors.accent.withValues(alpha: 0.08),
                  blurRadius:  20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.today_rounded, color: AppColors.accent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "TODAY'S REALITY",
                            style: TextStyle(
                              color:     AppColors.accent,
                              fontSize:  10,
                              fontWeight:FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  data?['fact'] as String? ??
                      'Loading today\'s reality check…',
                  style: const TextStyle(
                    color:      AppColors.textPrimary,
                    fontSize:   16,
                    fontWeight: FontWeight.w500,
                    height:     1.5,
                  ),
                ),
                if (data?['source'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        data!['source'] as String,
                        style: const TextStyle(
                          color:    AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
        );
      },
    );
  }
}
