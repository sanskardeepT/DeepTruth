import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class SourceChip extends StatelessWidget {
  final String source;

  const SourceChip({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final isUrl = source.startsWith('http');
    return GestureDetector(
      onTap: isUrl
          ? () async {
              final uri = Uri.tryParse(source);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_rounded, color: AppColors.accent, size: 10),
            const SizedBox(width: 3),
            Text(
              source.length > 40 ? '${source.substring(0, 40)}…' : source,
              style: const TextStyle(color: AppColors.accent, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
