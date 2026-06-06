import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/check_result.dart';

class ReelResultCard extends StatelessWidget {
  final CheckResult result;

  const ReelResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(result.truthScore);
    
    // Detect platform
    final contentLower = result.originalContent.toLowerCase();
    final isInstagram = contentLower.contains('instagram.com') || contentLower.contains('ig.me');
    final isYouTube = contentLower.contains('youtube.com') || contentLower.contains('youtu.be');

    String platformName = 'Generic Social Media';
    IconData platformIcon = Icons.share_rounded;
    Color platformColor = const Color(0xFF9B59B6);

    if (isInstagram) {
      platformName = 'Instagram Reel';
      platformIcon = Icons.camera_alt_rounded;
      platformColor = const Color(0xFFE1306C);
    } else if (isYouTube) {
      platformName = 'YouTube Short';
      platformIcon = Icons.play_arrow_rounded;
      platformColor = const Color(0xFFFF0000);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      color.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: platformColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(platformIcon, color: platformColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      platformName,
                      style: TextStyle(
                        color: platformColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                result.verdictEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score Ring + Verdict
          Row(
            children: [
              _TruthScoreRing(score: result.truthScore, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdict,
                      style: TextStyle(
                        color:      color,
                        fontSize:   22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.contentType.toUpperCase(),
                        style: const TextStyle(
                          color:        AppColors.textMuted,
                          fontSize:     10,
                          letterSpacing:0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original claim content prefill
          if (result.originalContent.isNotEmpty) ...[
            const Text(
              'Analyzed Claim:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              result.originalContent,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Explanation
          Text(
            result.explanation,
            style: const TextStyle(
              color:   AppColors.textPrimary,
              fontSize:14,
              height:  1.6,
            ),
          ),

          // Missing context
          if (result.missingContext != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.missingContext!,
                      style: const TextStyle(
                        color:   AppColors.warning,
                        fontSize:12,
                        height:  1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Manipulation Tactics / Alerts
          if (result.manipulationTactics.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: AppColors.danger, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Manipulation Alert: ${result.manipulationScore}/100',
                      style: const TextStyle(
                        color:      AppColors.danger,
                        fontSize:   12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing:    6,
                  runSpacing: 4,
                  children: result.manipulationTactics.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(color: AppColors.danger, fontSize: 11),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ],

          // Sources
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CITED EVIDENCE & SOURCES',
                  style: TextStyle(
                    color:        AppColors.textMuted,
                    fontSize:     10,
                    fontWeight:   FontWeight.bold,
                    letterSpacing:1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.sources.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            color:   AppColors.textSecondary,
                            fontSize:11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }
}

class _TruthScoreRing extends StatelessWidget {
  final int score;
  final Color color;

  const _TruthScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  90,
      height: 90,
      child: CustomPaint(
        painter: _RingPainter(score: score, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color:      color,
                  fontSize:   26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  color:   AppColors.textMuted,
                  fontSize:9,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .scale(duration: 700.ms, curve: Curves.elasticOut, begin: const Offset(0.5, 0.5));
  }
}

class _RingPainter extends CustomPainter {
  final int score;
  final Color color;

  _RingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 5.0;

    // Background ring
    final bgPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color       = AppColors.divider;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round
      ..color       = color;

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.score != score || old.color != color;
}
