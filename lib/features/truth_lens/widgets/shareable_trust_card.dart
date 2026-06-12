import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';

class ShareableTrustCard extends StatelessWidget {
  final CheckResult result;
  final double aspectRatio;

  const ShareableTrustCard({
    super.key,
    required this.result,
    required this.aspectRatio,
  });

  String get _evidenceStrength {
    final score = result.truthScore;
    if (score >= 80) return 'Strong';
    if (score >= 50) return 'Medium';
    return 'Weak';
  }

  Color get _verdictColor {
    switch (result.verdict) {
      case 'TRUE': return AppColors.success;
      case 'FALSE': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM dd, yyyy · HH:mm').format(result.analyzedAt);

    // Layout configuration depending on aspect ratio
    // 9:16 (WhatsApp/Instagram Story), 1:1 (Instagram Square), 16:9 (X Post Landscape)
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = width / aspectRatio;

        return Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF070B1E), // Carbon deep slate midnight background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 2),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F2B), Color(0xFF050714)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Watermark
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DEEPTRUTH TIOS',
                    style: TextStyle(
                      color: AppColors.textAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),

              // Center Score Container
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: width * 0.35,
                    height: width * 0.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _verdictColor.withValues(alpha: 0.25), width: 8),
                      boxShadow: [
                        BoxShadow(
                          color: _verdictColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${result.truthScore}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VERDICT: ${result.verdict}',
                    style: TextStyle(
                      color: _verdictColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              // Bottom Stats and Details
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row of stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDetailItem('Evidence Strength', _evidenceStrength, AppColors.accent),
                      Container(height: 24, width: 1.5, color: AppColors.divider),
                      _buildDetailItem('Confidence', '${result.consensus?.confidenceScore ?? 90}%', Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider, thickness: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Scanned Claim: "${result.originalContent.length > 60 ? "${result.originalContent.substring(0, 60)}..." : result.originalContent}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verified at: $timeStr',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
