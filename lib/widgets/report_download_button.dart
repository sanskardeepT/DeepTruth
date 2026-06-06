import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/models/check_result.dart';
import '../core/models/impact_result.dart';
import '../core/services/report_service.dart';

class ReportDownloadButton extends StatefulWidget {
  final CheckResult checkResult;
  final ImpactResult? impactResult;

  const ReportDownloadButton({
    super.key,
    required this.checkResult,
    this.impactResult,
  });

  @override
  State<ReportDownloadButton> createState() => _ReportDownloadButtonState();
}

class _ReportDownloadButtonState extends State<ReportDownloadButton> {
  bool _isGenerating = false;
  bool _isDone       = false;

  Future<void> _generate() async {
    if (_isGenerating) return;
    if (mounted) setState(() => _isGenerating = true);

    try {
      await ReportService.instance.generateAndShare(
        widget.checkResult,
        widget.impactResult,
      );
      if (mounted) setState(() { _isDone = true; _isGenerating = false; });

      // Reset after 3 seconds
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _isDone = false);
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate report. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _generate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: _isDone
              ? const LinearGradient(colors: [AppColors.success, Color(0xFF00AA55)])
              : const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0099BB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isGenerating)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (_isDone)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              _isGenerating
                  ? 'Generating…'
                  : _isDone
                      ? 'Report Ready!'
                      : 'Download Full Report',
              style: const TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize:   15,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
