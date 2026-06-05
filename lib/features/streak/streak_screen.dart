import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/streak_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/loading_shimmer.dart';
import 'widgets/rank_progress_card.dart';
import 'widgets/achievement_badge.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StreakProvider>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.streakTitle),
        actions: [
          Consumer<StreakProvider>(
            builder: (_, sp, __) => TextButton.icon(
              onPressed: sp.streak.canFreeze
                  ? () => _showFreezeDialog(context, sp)
                  : null,
              icon: const Text('🧊', style: TextStyle(fontSize: 16)),
              label: Text(
                AppStrings.freezeStreak,
                style: TextStyle(
                  color: sp.streak.canFreeze
                      ? AppColors.accent
                      : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<StreakProvider>(
        builder: (_, sp, __) => RefreshIndicator(
          color:           AppColors.accent,
          backgroundColor: AppColors.bgCard,
          onRefresh: () async {
            sp.refresh();
            await sp.loadLeaderboard();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStreakHero(sp),
                const SizedBox(height: 20),
                RankProgressCard(streak: sp.streak),
                const SizedBox(height: 20),
                _buildStats(sp),
                const SizedBox(height: 20),
                _buildAchievements(sp),
                const SizedBox(height: 20),
                _buildLeaderboard(sp),
                const SizedBox(height: 16),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakHero(StreakProvider sp) {
    final streak = sp.streak;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.15),
            AppColors.bgCard,
          ],
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Fire emoji with pulse
          Text(
            streak.rankEmoji,
            style: const TextStyle(fontSize: 56),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.95, 0.95),
              end:   const Offset(1.05, 1.05),
              duration: 1200.ms,
            ),
          const SizedBox(height: 12),
          // Streak count
          Text(
            '${streak.currentStreak}',
            style: const TextStyle(
              color:      AppColors.textPrimary,
              fontSize:   64,
              fontWeight: FontWeight.bold,
              height:     1.0,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          Text(
            AppStrings.streakDays,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color:        const Color(0xFFFF6B35).withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border:       Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.4)),
            ),
            child: Text(
              streak.rank,
              style: const TextStyle(
                color:      Color(0xFFFF6B35),
                fontSize:   16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (streak.isStreakAtRisk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded,
                      color: AppColors.danger, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Streak at risk! Open app to maintain it.',
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildStats(StreakProvider sp) {
    final streak = sp.streak;
    final stats = [
      ('🏆', 'Best Streak', '${streak.longestStreak} days'),
      ('✅', 'Total Checks', '${streak.totalChecks}'),
      ('🎯', 'Fakes Caught', '${streak.fakesCaught}'),
    ];

    return Row(
      children: stats.asMap().entries.map((e) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(e.value.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                e.value.$3,
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize:   16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                e.value.$2,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate(delay: (e.key * 80).ms).fadeIn().scale(
          begin: const Offset(0.9, 0.9)),
      )).toList(),
    );
  }

  Widget _buildAchievements(StreakProvider sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACHIEVEMENTS',
          style: TextStyle(
            color:        AppColors.textMuted,
            fontSize:     11,
            fontWeight:   FontWeight.bold,
            letterSpacing:1.5,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AchievementBadge(
                emoji:    '🌱',
                label:    'First Step',
                unlocked: sp.streak.currentStreak >= 1,
              ),
              AchievementBadge(
                emoji:    '🔍',
                label:    'Observer',
                unlocked: sp.streak.currentStreak >= 7,
              ),
              AchievementBadge(
                emoji:    '📰',
                label:    'Reporter',
                unlocked: sp.streak.currentStreak >= 30,
              ),
              AchievementBadge(
                emoji:    '⚖️',
                label:    'Analyst',
                unlocked: sp.streak.currentStreak >= 90,
              ),
              AchievementBadge(
                emoji:    '🛡️',
                label:    'Guardian',
                unlocked: sp.streak.currentStreak >= 180,
              ),
              AchievementBadge(
                emoji:    '🌟',
                label:    'Sentinel',
                unlocked: sp.streak.currentStreak >= 365,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(StreakProvider sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEADERBOARD',
          style: TextStyle(
            color:        AppColors.textMuted,
            fontSize:     11,
            fontWeight:   FontWeight.bold,
            letterSpacing:1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (sp.isLoadingLeaderboard)
          const ListShimmer(count: 5)
        else if (sp.leaderboard.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Leaderboard loading…',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...sp.leaderboard.asMap().entries.take(10).map((e) {
            final entry = e.value;
            return _LeaderboardEntry(
              rank:       e.key + 1,
              name:       entry['displayName'] as String? ?? 'User',
              streak:     (entry['streakDays'] as num?)?.toInt() ?? 0,
              rankLabel:  entry['rank'] as String? ?? 'Newcomer',
              country:    entry['country'] as String? ?? '',
            );
          }),
      ],
    );
  }

  void _showFreezeDialog(BuildContext context, StreakProvider sp) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('🧊 Freeze Streak',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Use your monthly freeze to protect your streak for 1 day? '
          'You get 1 freeze per month.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              sp.freezeStreak();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Use Freeze'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEntry extends StatelessWidget {
  final int rank;
  final String name;
  final int streak;
  final String rankLabel;
  final String country;

  const _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.streak,
    required this.rankLabel,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3   = rank <= 3;
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textMuted;

    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:  isTop3
            ? rankColor.withOpacity(0.06)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? rankColor.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              isTop3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
              style: TextStyle(
                color:    rankColor,
                fontWeight: FontWeight.bold,
                fontSize: isTop3 ? 18 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(rankLabel,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: const TextStyle(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize:   14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
