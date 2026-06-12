import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';

class OsintDetailsPanel extends StatelessWidget {
  final CheckResult result;

  const OsintDetailsPanel({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final rep = result.reputation;
    final prov = result.provenance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Source Publisher Reputation
        _buildSectionHeader('1. Publisher Credibility Registry'),
        const SizedBox(height: 10),
        if (rep == null)
          _buildInfoBox(
            'NO DOMAIN REPUTATION INDEX AVAILABLE\nCould not fetch publisher history.',
            AppColors.textMuted,
            Icons.info_outline,
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rep.domain.toUpperCase(),
                      style: const TextStyle(
                        color:      AppColors.textAccent,
                        fontWeight: FontWeight.bold,
                        fontSize:   14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildTag(
                      'Trust Rating: ${rep.reputationScore}/100',
                      rep.reputationScore > 70
                          ? AppColors.success
                          : (rep.reputationScore > 40 ? AppColors.warning : AppColors.danger),
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 20),
                _buildInfoRow('Historical Accuracy Rate', '${rep.historicalAccuracy.toStringAsFixed(1)}%'),
                _buildInfoRow('Verified Accuracy Scans', '${rep.verificationSuccess} tasks'),
                _buildInfoRow('Manipulation Flag Incidents', '${rep.manipulationIncidents} flags'),
                _buildInfoRow('Transparency Tier Rating', rep.transparency),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // 2. Coordinated Campaign & Bot Networks
        _buildSectionHeader('2. Narrative Tracking & Bot Networks'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Propagation Footprint Scan',
                      style: TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                  ),
                  _buildTag(
                    'REUSED COUNT: ${prov?.reusedCount ?? 0}',
                    (prov?.reusedCount ?? 0) > 3 ? AppColors.warning : AppColors.success,
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 20),
              _buildInfoRow('First Appearance Date', prov?.firstAppearance ?? 'Not Found'),
              _buildInfoRow('Primary Distribution Domain', prov?.sourceDomain ?? 'unknown.com'),
              _buildInfoRow('Bot Cluster Correlation Risk', (prov?.reusedCount ?? 0) > 3 ? 'MODERATE' : 'LOW'),
              _buildInfoRow('Coordinated Campaign Index', (prov?.reusedCount ?? 0) > 4 ? 'HIGH_VELOCITY' : 'STABLE_DISSEMINATION'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color:        AppColors.accent,
        fontSize:     11,
        fontWeight:   FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color, IconData icon) {
    return Container(
      width:        double.infinity,
      padding:      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
