import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app.dart';

class QuickActionChips extends StatelessWidget {
  const QuickActionChips({super.key});

  static const _actions = [
    _QuickAction('Truth Lens', Icons.policy_rounded,     AppColors.accent,   1),
    _QuickAction('Fake News',  Icons.newspaper_rounded,   AppColors.danger,   2),
    _QuickAction('TraceIQ',   Icons.manage_search_rounded,AppColors.warning,  3),
    _QuickAction('ReelIQ',    Icons.play_circle_rounded,  Color(0xFF9B59B6),  4),
    _QuickAction('AskIQ',     Icons.chat_bubble_rounded,  AppColors.success,  5),
    _QuickAction('Streak',    Icons.local_fire_department_rounded, Color(0xFFFF6B35), 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color:        AppColors.textMuted,
              fontSize:     11,
              fontWeight:   FontWeight.bold,
              letterSpacing:1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount:   _actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final action = _actions[i];
              return _ActionChip(action: action, index: i);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final _QuickAction action;
  final int index;

  const _ActionChip({required this.action, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Map action index to bottom nav tab
        final tabIndex = action.tabIndex - 1;
        // Find MainShell and switch tab
        context.findAncestorStateOfType<MainShellState>()?.setIndex(tabIndex);
      },
      child: Container(
        width:   80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 26),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                color:    AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate(delay: (index * 60).ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final int tabIndex;

  const _QuickAction(this.label, this.icon, this.color, this.tabIndex);
}
