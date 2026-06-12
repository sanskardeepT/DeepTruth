import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/check_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/loading_shimmer.dart';
import 'widgets/check_input_box.dart';
import 'widgets/verification_console.dart';

class TruthLensScreen extends StatefulWidget {
  const TruthLensScreen({super.key});

  @override
  State<TruthLensScreen> createState() => _TruthLensScreenState();
}

class _TruthLensScreenState extends State<TruthLensScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CheckProvider>();
    if (cp.prefilledContent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.text = cp.prefilledContent!;
        cp.clearPrefill();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.truthLensTitle),
        actions: [
          if (cp.isDone)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              tooltip: 'New Check',
              onPressed: () {
                cp.reset();
                _textController.clear();
              },
            ),
        ],
      ),
      body: Column(
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
    );
  }

  Widget _buildContent(BuildContext context, CheckProvider cp) {
    switch (cp.state) {
      case CheckState.idle:
        return Column(
          children: [
            _buildHero(),
            const SizedBox(height: 24),
            CheckInputBox(
              controller: _textController,
              onSubmit: (text, imagePath) => cp.analyze(text, imagePath: imagePath),
            ),
            const SizedBox(height: 24),
            _buildTips(),
          ],
        );

      case CheckState.loading:
      case CheckState.loadingImpact:
        return Column(
          children: [
            const SizedBox(height: 20),
            _buildLoadingState(cp.state),
          ],
        );

      case CheckState.done:
        if (cp.result == null) return const SizedBox.shrink();
        return VerificationConsoleWidget(
          result: cp.result!,
          impact: cp.impactResult,
          onReset: () {
            cp.reset();
            _textController.clear();
          },
        );

      case CheckState.error:
        return AppErrorWidget(
          message:    cp.errorMessage ?? AppStrings.errorGeneral,
          icon:       Icons.error_outline_rounded,
          onRetry:    () {
            cp.reset();
            _textController.clear();
          },
        );
    }
  }

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width:  90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF1A4080), Color(0xFF0A0E27)],
            ),
            border: Border.all(color: AppColors.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color:      AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.policy_rounded,
            color:  AppColors.accent,
            size:   42,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          'Truth Lens',
          style: TextStyle(
            color:      AppColors.textPrimary,
            fontSize:   26,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        const Text(
          'Paste any news, claim, URL, or screenshot text.\nGet instant AI-verified truth score.',
          style: TextStyle(
            color:   AppColors.textSecondary,
            fontSize:13,
            height:  1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildLoadingState(CheckState state) {
    return Column(
      children: [
        Container(
          width:   64,
          height:  64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color:       AppColors.accent,
              strokeWidth: 2.5,
            ),
          ),
        ).animate().scale().then().shimmer(duration: 1500.ms),
        const SizedBox(height: 20),
        Text(
          state == CheckState.loadingImpact
              ? 'Calculating personal impact…'
              : AppStrings.analyzingLabel,
          style: const TextStyle(
            color:      AppColors.textSecondary,
            fontSize:   14,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 32),
        const CheckResultShimmer(),
      ],
    );
  }

  Widget _buildTips() {
    const tips = [
      ('📰', 'Paste news headlines or full articles'),
      ('🔗', 'Drop in social media post URLs'),
      ('💬', 'Type out any claim or statement'),
      ('📱', 'Describe reel content or screenshot text'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHAT YOU CAN CHECK',
          style: TextStyle(
            color:        AppColors.textMuted,
            fontSize:     11,
            fontWeight:   FontWeight.bold,
            letterSpacing:1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(e.value.$1, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text(
                e.value.$2,
                style: const TextStyle(
                  color:   AppColors.textSecondary,
                  fontSize:13,
                ),
              ),
            ],
          ).animate(delay: (e.key * 60).ms).fadeIn().slideX(begin: -0.1),
        )),
      ],
    );
  }
}
