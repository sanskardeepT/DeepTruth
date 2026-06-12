import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';
import '../../../../core/models/impact_result.dart';
import '../../../../core/services/verification_pipeline_orchestrator.dart';
import '../../../../widgets/report_download_button.dart';
import 'score_gauge.dart';
import 'forensics_panel.dart';
import 'osint_details_panel.dart';
import 'trust_graph_painter.dart';

class VerificationConsoleWidget extends StatefulWidget {
  final CheckResult result;
  final ImpactResult? impact;
  final VoidCallback onReset;

  const VerificationConsoleWidget({
    super.key,
    required this.result,
    this.impact,
    required this.onReset,
  });

  @override
  State<VerificationConsoleWidget> createState() => _VerificationConsoleWidgetState();
}

class _VerificationConsoleWidgetState extends State<VerificationConsoleWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  
  String? _userFeedback; // 'helpful' | 'not_helpful'
  bool _feedbackSubmitted = false;
  final _commentController = TextEditingController();
  bool _isSubmittingFeedback = false;

  static const _tabTitles = [
    'System Verdict',
    'Forensics',
    'Network OSINT',
    'Trust Graph',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consensus = widget.result.consensus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Headers
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          labelColor:     AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: AppColors.divider,
          tabs: _tabTitles.map((t) => Tab(text: t.toUpperCase())).toList(),
        ),
        const SizedBox(height: 16),
        // Tab Body
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return _buildActiveTab(consensus);
          },
        ),
        const SizedBox(height: 24),
        // Action Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Check Another'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              onPressed: widget.onReset,
            ),
            ReportDownloadButton(
              checkResult: widget.result,
              impactResult: widget.impact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTab(dynamic consensus) {
    switch (_tabController.index) {
      case 0:
        return _buildVerdictOverviewTab(consensus);
      case 1:
        return ForensicsPanel(result: widget.result);
      case 2:
        return OsintDetailsPanel(result: widget.result);
      case 3:
        return TrustGraphWidget(graph: widget.result.trustGraph!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVerdictOverviewTab(dynamic consensus) {
    final int auth = consensus?.authenticityScore ?? widget.result.truthScore;
    final int trust = consensus?.trustScore ?? widget.result.truthScore;
    final int manip = consensus?.manipulationScore ?? widget.result.manipulationScore;
    final int risk = consensus?.riskScore ?? 0;
    final int confidence = consensus?.confidenceScore ?? 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Core Verdict Header
        _buildVerdictHeader(widget.result.verdict, trust),
        const SizedBox(height: 20),

        // Score Gauges Group
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ScoreGauge(score: trust, label: 'Trust', color: AppColors.scoreColor(trust)),
              const SizedBox(width: 14),
              ScoreGauge(score: auth, label: 'Authenticity', color: Colors.blue),
              const SizedBox(width: 14),
              ScoreGauge(score: manip, label: 'Manipulation', color: AppColors.danger),
              const SizedBox(width: 14),
              ScoreGauge(score: risk, label: 'Risk', color: Colors.orange),
              const SizedBox(width: 14),
              ScoreGauge(score: confidence, label: 'Confidence', color: Colors.purple),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Explanation text
        const Text(
          'FORENSIC CONCLUSION:',
          style: TextStyle(
            color:        AppColors.textMuted,
            fontSize:     10,
            fontWeight:   FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            widget.result.explanation,
            style: const TextStyle(
              color:  AppColors.textPrimary,
              fontSize:13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Explainability Adjustments Tree
        if (consensus != null && (consensus.adjustments as List).isNotEmpty) ...[
          const Text(
            'TRUST SCORE EXPLAINABILITY TREE:',
            style: TextStyle(
              color:        AppColors.textMuted,
              fontSize:     10,
              fontWeight:   FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...consensus.adjustments.map<Widget>((adj) {
            final int imp = adj['impact'] as int;
            final isPos = imp >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    isPos ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                    color: isPos ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      adj['factor'] as String,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${isPos ? "+" : ""}$imp',
                    style: TextStyle(
                      color:      isPos ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize:   12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        _buildFeedbackWidget(),
      ],
    );
  }

  Widget _buildFeedbackWidget() {
    if (_feedbackSubmitted) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback Submitted!',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Thank you. Your feedback will help train future on-device ML models.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Was this verification verdict accurate & helpful?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _userFeedback = 'helpful';
                    });
                  },
                  icon: const Icon(Icons.thumb_up_rounded, size: 14),
                  label: const Text('Yes, Helpful'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _userFeedback == 'helpful' ? AppColors.primary : AppColors.success,
                    backgroundColor: _userFeedback == 'helpful' ? AppColors.success : Colors.transparent,
                    side: BorderSide(
                      color: _userFeedback == 'helpful' ? AppColors.success : AppColors.success.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _userFeedback = 'not_helpful';
                    });
                  },
                  icon: const Icon(Icons.thumb_down_rounded, size: 14),
                  label: const Text('No, Unhelpful'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _userFeedback == 'not_helpful' ? AppColors.primary : AppColors.danger,
                    backgroundColor: _userFeedback == 'not_helpful' ? AppColors.danger : Colors.transparent,
                    side: BorderSide(
                      color: _userFeedback == 'not_helpful' ? AppColors.danger : AppColors.danger.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (_userFeedback != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Any additional context or correction links? (Optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: _isSubmittingFeedback ? null : _submitFeedbackAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSubmittingFeedback
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Text(
                        'Submit Verification Rating',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitFeedbackAction() async {
    if (_userFeedback == null) return;
    setState(() => _isSubmittingFeedback = true);
    
    // Calculate fallback hash if consensus model is not filled (for claim scans)
    final hash = widget.result.sha256Hash ?? 'unknown_hash';
    
    await VerificationPipelineOrchestrator.instance.submitFeedback(
      reportId: widget.result.reportId,
      sha256Hash: hash,
      feedback: _userFeedback!,
      comment: _commentController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmittingFeedback = false;
        _feedbackSubmitted = true;
      });
    }
  }


  Widget _buildVerdictHeader(String verdict, int score) {
    Color color = AppColors.scoreColor(score);
    IconData icon;

    switch (verdict) {
      case 'TRUE':
        icon = Icons.verified_rounded;
      case 'FALSE':
        icon = Icons.cancel_rounded;
      case 'MISLEADING':
        icon = Icons.warning_rounded;
      default:
        icon = Icons.help_rounded;
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VERDICT: $verdict',
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.bold,
                    fontSize:   18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consensus weighted confidence verified at $score%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
