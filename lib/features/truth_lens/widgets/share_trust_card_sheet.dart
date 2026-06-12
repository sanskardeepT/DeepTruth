import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';
import 'shareable_trust_card.dart';

class ShareTrustCardSheet extends StatefulWidget {
  final CheckResult result;

  const ShareTrustCardSheet({
    super.key,
    required this.result,
  });

  @override
  State<ShareTrustCardSheet> createState() => _ShareTrustCardSheetState();
}

class _ShareTrustCardSheetState extends State<ShareTrustCardSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  double _selectedAspectRatio = 1.0; // Default: Instagram Feed (1:1)
  bool _isSharing = false;

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    try {
      // Small delay to ensure rendering completes
      await Future<void>.delayed(const Duration(milliseconds: 300));
      
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('RepaintBoundary not found.');

      final image = await boundary.toImage(pixelRatio: 3.0); // High-DPI export
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final score = widget.result.truthScore;
        final verdict = widget.result.verdict;
        await Share.shareXFiles(
          [XFile.fromData(pngBytes, name: 'deeptruth_verified.png', mimeType: 'image/png')],
          text: 'Verified by DeepTruth OS. Verdict: $verdict (Trust Score: $score/100). Verify your content now with DeepTruth!',
        );
      }
    } catch (e) {
      debugPrint('Failed to share card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share card: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SHARE VERIFICATION CARD',
                style: TextStyle(
                  color: AppColors.textAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select platform layout optimization:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          // Aspect Ratio Selection Chips
          Row(
            children: [
              _buildAspectChip('WhatsApp Status / Story (9:16)', 9 / 16),
              const SizedBox(width: 8),
              _buildAspectChip('Instagram Feed (1:1)', 1.0),
              const SizedBox(width: 8),
              _buildAspectChip('X / Landscape (16:9)', 16 / 9),
            ],
          ),
          const SizedBox(height: 24),
          
          // Card Preview Area wrapped in RepaintBoundary
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: RepaintBoundary(
                key: _repaintKey,
                child: ShareableTrustCard(
                  result: widget.result,
                  aspectRatio: _selectedAspectRatio,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSharing ? null : _shareCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
                      'Share Verification Card',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectChip(String label, double ratio) {
    final isSelected = _selectedAspectRatio == ratio;
    return ChoiceChip(
      label: Text(
        label.split(' (')[0],
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.bgSecondary,
      side: BorderSide(color: isSelected ? AppColors.accent : AppColors.divider),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedAspectRatio = ratio);
        }
      },
    );
  }
}
