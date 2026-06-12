import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';

class ForensicsPanel extends StatelessWidget {
  final CheckResult result;

  const ForensicsPanel({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final c2pa = result.c2pa;
    final prov = result.provenance;
    final df = result.deepfake;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. C2PA Registry Verification Section
        _buildSectionHeader('1. Cryptographic Signature Validation (C2PA)'),
        const SizedBox(height: 10),
        if (c2pa == null || !c2pa.hasC2PA)
          _buildWarningBox('NO CRYPTOGRAPHIC SIGNATURE EMBEDDED\nThis asset does not contain C2PA JUMBF Content Credentials.')
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c2pa.verificationStatus,
                        style: const TextStyle(
                          color:      AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                        ),
                      ),
                    ),
                    _buildTag('Score: ${c2pa.trustScore}/100', AppColors.success),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 20),
                _buildInfoRow('Creator', c2pa.creator ?? 'Unknown'),
                _buildInfoRow('Publisher', c2pa.publisher ?? 'Unknown'),
                _buildInfoRow('Creation Timestamp', c2pa.createdAt ?? 'Unknown'),
                if (c2pa.editedBy.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'EDIT HISTORY / ACTIONS PERMED:',
                    style: TextStyle(
                      color:        AppColors.textMuted,
                      fontSize:     10,
                      fontWeight:   FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: c2pa.editedBy.map((action) => _buildActionChip(action)).toList(),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),

        // 2. EXIF Metadata Extraction
        _buildSectionHeader('2. Physical Hardware Metadata (EXIF)'),
        const SizedBox(height: 10),
        if (prov == null || prov.exif.isEmpty)
          _buildWarningBox('EXIF DATA MISSING OR STRIPPED\nCannot analyze device hardware headers.')
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: prov.exif.entries.map((e) => _buildInfoRow(e.key, e.value)).toList(),
            ),
          ),
        const SizedBox(height: 24),

        // 3. Multimodal Deepfake Diagnostics
        _buildSectionHeader('3. Synthetic Media Classifier Pipeline'),
        const SizedBox(height: 10),
        if (df == null)
          _buildWarningBox('Deepfake diagnostic pipeline unavailable.')
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(
                color: (df.deepfakeProbability > 50 ? AppColors.danger : AppColors.divider).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ensemble Scanning Status',
                      style: TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                    _buildTag(
                      'RISK: ${df.riskLevel.toUpperCase()}',
                      df.deepfakeProbability > 50 ? AppColors.danger : AppColors.success,
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 20),
                _buildProgressIndicator('Visual Artifact Risk (GAN/FaceSwap)', df.imageRisk),
                _buildProgressIndicator('Temporal Frame Consistency Risk', df.videoRisk),
                _buildProgressIndicator('Audio Voice Cloning Spectrogram Risk', df.audioRisk),
                _buildProgressIndicator('Cross-modal Fusion Divergence', df.multimodalRisk),
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

  Widget _buildWarningBox(String text) {
    return Container(
      width:        double.infinity,
      padding:      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.warning,
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

  Widget _buildActionChip(String action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Text(
        action,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double val) {
    final Color color = val > 70 ? AppColors.danger : (val > 35 ? AppColors.warning : AppColors.success);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text('${val.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           val / 100.0,
              backgroundColor: AppColors.primaryLight,
              color:           color,
              minHeight:       5,
            ),
          ),
        ],
      ),
    );
  }
}
