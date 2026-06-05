import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/osint_result.dart';

class OsintResultCard extends StatelessWidget {
  final OsintResult result;

  const OsintResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.hasError) {
      return _buildErrorCard();
    }

    final riskColor = _riskColor(result.riskLevel);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: riskColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_queryIcon(result.queryType),
                  color: riskColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.query,
                  style: const TextStyle(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize:   14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _RiskBadge(level: result.riskLevel, color: riskColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          // Findings
          ...result.findings.asMap().entries.map((e) => _FindingRow(
            finding: e.value,
            index:   e.key,
          )),
          // Sources
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'DATA SOURCES',
              style: TextStyle(
                color:        AppColors.textMuted,
                fontSize:     10,
                letterSpacing:1.0,
                fontWeight:   FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing:    6,
              runSpacing: 4,
              children: result.sources.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border:       Border.all(color: AppColors.divider),
                ),
                child: Text(s,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Data from public sources only. LensIQ does not store this information.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.error!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high':   return AppColors.danger;
      case 'medium': return AppColors.warning;
      case 'low':    return AppColors.success;
      default:       return AppColors.textMuted;
    }
  }

  IconData _queryIcon(OsintQueryType type) {
    switch (type) {
      case OsintQueryType.email:    return Icons.email_rounded;
      case OsintQueryType.phone:    return Icons.phone_rounded;
      case OsintQueryType.username: return Icons.alternate_email;
      case OsintQueryType.ip:       return Icons.router_rounded;
      case OsintQueryType.website:  return Icons.language_rounded;
      default:                      return Icons.search_rounded;
    }
  }
}

class _FindingRow extends StatelessWidget {
  final OsintFinding finding;
  final int index;

  const _FindingRow({required this.finding, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              finding.label,
              style: const TextStyle(
                color:    AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: finding.sourceUrl != null
                ? GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(finding.sourceUrl!);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      finding.value,
                      style: const TextStyle(
                        color:      AppColors.accent,
                        fontSize:   12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    finding.value,
                    style: const TextStyle(
                      color:   AppColors.textPrimary,
                      fontSize:12,
                    ),
                  ),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.1);
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;
  final Color color;

  const _RiskBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${level.toUpperCase()} RISK',
        style: TextStyle(
          color:      color,
          fontSize:   10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
