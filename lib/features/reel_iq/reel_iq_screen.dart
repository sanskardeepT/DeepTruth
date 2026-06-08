import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/check_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/report_download_button.dart';
import 'package:provider/provider.dart';
import 'widgets/reel_result_card.dart';

class ReelIQScreen extends StatefulWidget {
  const ReelIQScreen({super.key});

  @override
  State<ReelIQScreen> createState() => _ReelIQScreenState();
}

class _ReelIQScreenState extends State<ReelIQScreen> {
  final _controller = TextEditingController();
  String? _selectedImagePath;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          setState(() {
            _selectedImagePath = image.path;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reelIQTitle),
        actions: [
          Consumer<CheckProvider>(
            builder: (_, cp, __) => cp.isDone
                ? IconButton(
                    icon:    const Icon(Icons.refresh_rounded, color: AppColors.accent),
                    tooltip: 'New Check',
                    onPressed: () {
                      cp.reset();
                      _controller.clear();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<CheckProvider>(
        builder: (_, cp, __) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContent(context, cp),
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CheckProvider cp) {
    switch (cp.state) {
      case CheckState.idle:
        return Column(
          children: [
            _buildHero(),
            const SizedBox(height: 24),
            _buildInputArea(context, cp),
            const SizedBox(height: 24),
            _buildExamples(context, cp),
          ],
        );

      case CheckState.loading:
      case CheckState.loadingImpact:
        return const Column(
          children: [
            SizedBox(height: 40),
            CheckResultShimmer(),
          ],
        );

      case CheckState.done:
        if (cp.result == null) return const SizedBox.shrink();
        return Column(
          children: [
            ReelResultCard(result: cp.result!),
            const SizedBox(height: 16),
            ReportDownloadButton(
              checkResult:  cp.result!,
              impactResult: cp.impactResult,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () { cp.reset(); _controller.clear(); },
              child: const Text('Check Another Reel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        );

      case CheckState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  cp.errorMessage ?? AppStrings.errorGeneral,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: cp.reset,
                  child: const Text(AppStrings.retryBtn,
                      style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
                colors: [Color(0xFF4A0080), Color(0xFF0A0E27)]),
            border: Border.all(color: const Color(0xFF9B59B6), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.25),
                  blurRadius: 24)
            ],
          ),
          child: const Icon(Icons.play_circle_rounded,
              color: Color(0xFF9B59B6), size: 40),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text('ReelIQ', style: TextStyle(
          color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Paste a reel URL, post link, or describe a viral claim.\nGet instant truth verification.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInputArea(BuildContext context, CheckProvider cp) {
    final canSubmit = _controller.text.trim().isNotEmpty || _selectedImagePath != null;
    return Column(
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(hintText: AppStrings.reelHint),
          onChanged: (_) {
            if (mounted) setState(() {});
          },
        ),
        if (_selectedImagePath != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImagePath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attached Reel Screenshot',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedImagePath!.split(Platform.pathSeparator).last,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  onPressed: () {
                    if (mounted) setState(() => _selectedImagePath = null);
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_search_rounded, size: 16),
              label: Text(_selectedImagePath == null ? 'Attach Screenshot' : 'Change Image'),
              style: TextButton.styleFrom(
                foregroundColor: _selectedImagePath == null ? AppColors.textMuted : AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canSubmit ? () {
              var text = _controller.text.trim();
              if (text.isEmpty && _selectedImagePath != null) {
                text = "Verification analysis of the attached reel screenshot.";
              }
              cp.analyze('REEL/SOCIAL MEDIA CONTENT:\n$text', imagePath: _selectedImagePath);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF9B59B6).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_rounded, size: 20),
                SizedBox(width: 8),
                Text(AppStrings.reelAnalyzeBtn,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamples(BuildContext context, CheckProvider cp) {
    const examples = [
      '🩺 "Drinking hot water kills COVID virus" — viral WhatsApp message',
      '💰 "Government giving ₹10,000 to everyone" — forwarded claim',
      '🏛 "Politician X said Y" — viral screenshot',
      '🌍 "New country joined India" — trending reel',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRY AN EXAMPLE', style: TextStyle(
            color: AppColors.textMuted, fontSize: 11,
            fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        ...examples.asMap().entries.map((e) => GestureDetector(
          onTap: () {
            _controller.text = e.value;
            cp.analyze('REEL/SOCIAL MEDIA CONTENT:\n${e.value}');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(e.value, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
          ).animate(delay: (e.key * 60).ms).fadeIn().slideX(begin: 0.1),
        )),
      ],
    );
  }
}
