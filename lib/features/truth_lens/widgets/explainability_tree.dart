import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/trust_verification_models.dart';

class TrustScoreExplainabilityTree extends StatelessWidget {
  final ConsensusScores consensus;

  const TrustScoreExplainabilityTree({super.key, required this.consensus});

  @override
  Widget build(BuildContext context) {
    final adjs = consensus.adjustments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_tree_rounded, color: AppColors.textAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'TRUST SCORE EXPLAINABILITY TREE',
              style: TextStyle(
                color: AppColors.textAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // Root Node: The Final Consensus Trust Score
              _buildRootNode(),
              // Connecting Trunk line
              Container(
                width: 2,
                height: 24,
                color: AppColors.divider,
              ),
              // Branches
              if (adjs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No breakdown factors computed for this check.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              else
                ...adjs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final adj = entry.value;
                  final isLast = idx == adjs.length - 1;

                  return _buildBranchNode(
                    category: adj['category'] as String? ?? 'general',
                    factor: adj['factor'] as String? ?? 'Consensus factor check',
                    impact: adj['impact'] as int? ?? 0,
                    isLast: isLast,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRootNode() {
    final score = consensus.trustScore;
    final color = AppColors.scoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score/100',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'VERDICT: ${consensus.verdict}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Consensus confidence level: ${consensus.confidenceScore}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchNode({
    required String category,
    required String factor,
    required int impact,
    required bool isLast,
  }) {
    String title;
    IconData icon;
    Color iconColor;

    switch (category) {
      case 'provenance':
        title = 'Metadata Provenance';
        icon = Icons.camera_enhance_rounded;
        iconColor = Colors.blue;
        break;
      case 'reputation':
        title = 'Publisher Reputation';
        icon = Icons.domain_rounded;
        iconColor = Colors.orange;
        break;
      case 'osint':
        title = 'OSINT Threat Index';
        icon = Icons.bug_report_rounded;
        iconColor = Colors.purple;
        break;
      case 'forensics':
        title = 'Visual Forensics';
        icon = Icons.remove_red_eye_rounded;
        iconColor = Colors.red;
        break;
      case 'factcheck':
        title = 'Fact Citation Index';
        icon = Icons.fact_check_rounded;
        iconColor = Colors.green;
        break;
      default:
        title = 'Consensus Vector';
        icon = Icons.analytics_rounded;
        iconColor = AppColors.accent;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection connector lines
          const SizedBox(width: 48), // Padding to shift branch nodes right
          Column(
            children: [
              Container(
                width: 2,
                height: 12,
                color: AppColors.divider,
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                  ),
                )
              else
                const Expanded(
                  child: SizedBox.shrink(),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Branch Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    // Component Weight Score Circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$impact',
                            style: TextStyle(
                              color: impact >= 15 ? AppColors.success : (impact >= 8 ? AppColors.warning : AppColors.danger),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '/20',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: iconColor, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                title.toUpperCase(),
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            factor,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
