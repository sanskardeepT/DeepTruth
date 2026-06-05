import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/impact_result.dart';

class ImpactDetailSheet extends StatelessWidget {
  final ImpactResult impact;

  const ImpactDetailSheet({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'HOW THIS AFFECTS YOU',
                style: TextStyle(
                  color:        AppColors.accent,
                  fontSize:     11,
                  fontWeight:   FontWeight.bold,
                  letterSpacing:1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            impact.directImpact,
            style: const TextStyle(
              color:   AppColors.textPrimary,
              fontSize:14,
              height:  1.6,
            ),
          ),
          if (impact.financialImpact != null) ...[
            const SizedBox(height: 10),
            _buildImpactRow(
              icon:  Icons.attach_money_rounded,
              color: AppColors.success,
              label: 'Financial Impact',
              value: impact.financialImpact!,
            ),
          ],
          if (impact.healthImpact != null) ...[
            const SizedBox(height: 8),
            _buildImpactRow(
              icon:  Icons.favorite_rounded,
              color: AppColors.danger,
              label: 'Health Impact',
              value: impact.healthImpact!,
            ),
          ],
          if (_hasTimeline) ...[
            const SizedBox(height: 16),
            const Text(
              'FUTURE TIMELINE',
              style: TextStyle(
                color:        AppColors.textMuted,
                fontSize:     10,
                fontWeight:   FontWeight.bold,
                letterSpacing:1.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimeline(),
          ],
          if (impact.actionableSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'WHAT YOU CAN DO',
              style: TextStyle(
                color:        AppColors.textMuted,
                fontSize:     10,
                fontWeight:   FontWeight.bold,
                letterSpacing:1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...impact.actionableSteps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width:   20,
                    height:  20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color:      AppColors.primary,
                        fontSize:   10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color:   AppColors.textSecondary,
                        fontSize:13,
                        height:  1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (impact.affectedPeopleDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        AppColors.info.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: AppColors.info, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      impact.affectedPeopleDescription,
                      style: const TextStyle(color: AppColors.info, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
  }

  bool get _hasTimeline =>
      impact.futureImpact6Months.isNotEmpty ||
      impact.futureImpact1Year.isNotEmpty ||
      impact.futureImpact5Years.isNotEmpty;

  Widget _buildImpactRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color:      color,
                  fontSize:   10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color:   AppColors.textSecondary,
                  fontSize:12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final items = [
      ('6 Mo', impact.futureImpact6Months, AppColors.info),
      ('1 Yr',  impact.futureImpact1Year,  AppColors.success),
      ('5 Yrs', impact.futureImpact5Years, AppColors.warning),
    ].where((i) => i.$2.isNotEmpty).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((e) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: e.key < items.length - 1 ? 8 : 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        (e.value.$3 as Color).withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              top: BorderSide(color: e.value.$3 as Color, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.value.$1,
                style: TextStyle(
                  color:      e.value.$3 as Color,
                  fontSize:   10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                e.value.$2,
                style: const TextStyle(
                  color:   AppColors.textSecondary,
                  fontSize:11,
                  height:  1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
