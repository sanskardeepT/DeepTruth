import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/check_result.dart';
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
            _buildHistoryList(context, cp),
          ],
        );

      case CheckState.loading:
      case CheckState.loadingImpact:
        return Column(
          children: [
            const SizedBox(height: 20),
            _buildLoadingState(cp),
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

  static const Map<String, List<String>> _pipelineStages = {
    'image': [
      'Local Cryptographic SHA-256 Hashing',
      'Evidence Vault Cache Registry Lookup',
      'Secure C2PA Digital Signature Manifest Check',
      'EXIF Metadata & Capture Provenance Parse',
      'Deepfake Image Probability Scan',
      'Google Visual Search Source Crawling',
      'Reputation & Consensus Weighted Calibration',
      'Evidence Vault Index Archival Sync',
    ],
    'video': [
      'Local Cryptographic SHA-256 Hashing',
      'Evidence Vault Cache Registry Lookup',
      'Temporal Video Frame Parsing',
      'Publisher Reputation & Consensus Score Check',
      'Evidence Vault Index Archival Sync',
    ],
    'url': [
      'Local Cryptographic SHA-256 Hashing',
      'Evidence Vault Cache Registry Lookup',
      'VirusTotal & URLScan Security Logs Analysis',
      'Wayback Machine Historical Archival Age Check',
      'Consensus Score Calculation & Verdict Compile',
      'Evidence Vault Index Archival Sync',
    ],
    'text': [
      'Local Cryptographic SHA-256 Hashing',
      'Evidence Vault Cache Registry Lookup',
      'Google Fact Check Explorer Search',
      'Consensus Score Calculation & Verdict Compile',
      'Evidence Vault Index Archival Sync',
    ],
  };

  int _getCurrentStageIndex(String inputType, String rawStage) {
    if (rawStage.isEmpty) return 0;
    final lower = rawStage.toLowerCase();
    
    if (inputType == 'image') {
      if (lower.contains('hash')) return 0;
      if (lower.contains('cache')) return 1;
      if (lower.contains('cloud') || lower.contains('evidence vault')) return 1;
      if (lower.contains('parallel') || lower.contains('plugin') || lower.contains('c2pa') || lower.contains('signature')) return 2;
      if (lower.contains('exif') || lower.contains('metadata') || lower.contains('provenance') || lower.contains('camera')) return 3;
      if (lower.contains('deepfake') || lower.contains('visual indicator')) return 4;
      if (lower.contains('google') || lower.contains('visual search') || lower.contains('crawl')) return 5;
      if (lower.contains('reputation') || lower.contains('consensus') || lower.contains('weighted')) return 6;
      if (lower.contains('saving') || lower.contains('vault') || lower.contains('synchronizing')) return 7;
    } else if (inputType == 'video') {
      if (lower.contains('hash')) return 0;
      if (lower.contains('cache') || lower.contains('vault')) {
        if (lower.contains('save') || lower.contains('result')) return 4;
        return 1;
      }
      if (lower.contains('frame') || lower.contains('temporal')) return 2;
      if (lower.contains('reputation') || lower.contains('publisher') || lower.contains('consensus')) return 3;
      if (lower.contains('saving') || lower.contains('vault') || lower.contains('synchronizing')) return 4;
    } else if (inputType == 'url') {
      if (lower.contains('hash')) return 0;
      if (lower.contains('cache') || lower.contains('vault')) {
        if (lower.contains('save') || lower.contains('result')) return 5;
        return 1;
      }
      if (lower.contains('security') || lower.contains('virustotal') || lower.contains('urlscan')) return 2;
      if (lower.contains('wayback') || lower.contains('archival') || lower.contains('snapshot')) return 3;
      if (lower.contains('reputation') || lower.contains('consensus') || lower.contains('threat')) return 4;
      if (lower.contains('saving') || lower.contains('vault') || lower.contains('synchronizing')) return 5;
    } else if (inputType == 'text') {
      if (lower.contains('hash')) return 0;
      if (lower.contains('cache') || lower.contains('vault')) {
        if (lower.contains('save') || lower.contains('result')) return 4;
        return 1;
      }
      if (lower.contains('fact check') || lower.contains('query') || lower.contains('search')) return 2;
      if (lower.contains('consensus') || lower.contains('rating')) return 3;
      if (lower.contains('saving') || lower.contains('vault') || lower.contains('synchronizing')) return 4;
    }
    return 0;
  }

  Widget _buildLoadingState(CheckProvider cp) {
    final state = cp.state;
    final stage = cp.loadingStage;
    final inputType = cp.inputType;
    final stages = _pipelineStages[inputType] ?? _pipelineStages['text']!;
    final isImpactLoading = state == CheckState.loadingImpact;
    final activeIndex = isImpactLoading ? stages.length : _getCurrentStageIndex(inputType, stage);

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isImpactLoading ? 'VERIFICATION COMPLETED' : 'RUNNING VERIFICATION PIPELINE',
                    style: const TextStyle(
                      color: AppColors.textAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (!isImpactLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isImpactLoading
                    ? 'Synthesizing localized interest vectors'
                    : (stage.isNotEmpty ? stage : 'Initializing security handshake…'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 20),
              // Stages List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stages.length,
                itemBuilder: (context, idx) {
                  final isCompleted = idx < activeIndex;
                  final isActive = idx == activeIndex && !isImpactLoading;
                  final isPending = idx > activeIndex || (idx == activeIndex && isImpactLoading);

                  Color iconColor;
                  IconData iconData;
                  double textOpacity;
                  FontWeight textWeight;

                  if (isCompleted) {
                    iconColor = AppColors.success;
                    iconData = Icons.check_circle_rounded;
                    textOpacity = 0.6;
                    textWeight = FontWeight.normal;
                  } else if (isActive) {
                    iconColor = AppColors.accent;
                    iconData = Icons.radio_button_checked_rounded;
                    textOpacity = 1.0;
                    textWeight = FontWeight.bold;
                  } else {
                    iconColor = AppColors.textMuted.withValues(alpha: 0.4);
                    iconData = Icons.radio_button_off_rounded;
                    textOpacity = 0.4;
                    textWeight = FontWeight.normal;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(iconData, color: iconColor, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stages[idx],
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: textOpacity),
                              fontSize: 12,
                              fontWeight: textWeight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (isImpactLoading) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Calculating personal interest matches…',
                        style: TextStyle(
                          color: AppColors.success.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98), duration: 200.ms),
        const SizedBox(height: 24),
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

  List<CheckResult> _getHistory() {
    try {
      if (Hive.isBoxOpen(AppConstants.boxChecks)) {
        final box = Hive.box<String>(AppConstants.boxChecks);
        final list = <CheckResult>[];
        for (final key in box.keys) {
          final jsonStr = box.get(key);
          if (jsonStr != null) {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            list.add(CheckResult.fromJson(data));
          }
        }
        list.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
        return list;
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
    return [];
  }

  Widget _buildHistoryList(BuildContext context, CheckProvider cp) {
    final history = _getHistory();
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text(
          'RECENT VERIFICATIONS',
          style: TextStyle(
            color:        AppColors.textAccent,
            fontSize:     11,
            fontWeight:   FontWeight.bold,
            letterSpacing:1.5,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 5 ? 5 : history.length, // Cap history items on UI to 5
          itemBuilder: (context, index) {
            final item = history[index];
            final scoreColor = AppColors.scoreColor(item.truthScore);
            
            IconData typeIcon;
            if (item.contentType == 'image') {
              typeIcon = Icons.image_rounded;
            } else if (item.contentType == 'video') {
              typeIcon = Icons.videocam_rounded;
            } else if (item.contentType == 'url') {
              typeIcon = Icons.link_rounded;
            } else {
              typeIcon = Icons.text_snippet_rounded;
            }

            final title = item.originalContent.startsWith('/') 
                ? item.originalContent.split('/').last 
                : item.originalContent;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListTile(
                onTap: () => cp.loadResult(item),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: AppColors.textSecondary, size: 20),
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item.analyzedAt.toLocal().toString().substring(0, 16),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${item.truthScore}/100',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

