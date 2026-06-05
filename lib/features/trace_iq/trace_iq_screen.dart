import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/osint_result.dart';
import '../../core/services/osint_service.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/loading_shimmer.dart';
import 'widgets/osint_input_panel.dart';
import 'widgets/osint_result_card.dart';

class TraceIQScreen extends StatefulWidget {
  const TraceIQScreen({super.key});

  @override
  State<TraceIQScreen> createState() => _TraceIQScreenState();
}

class _TraceIQScreenState extends State<TraceIQScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  OsintResult? _result;
  bool _isLoading = false;
  String? _error;

  static const _tabs = [
    (AppStrings.traceEmail,    Icons.email_outlined,       OsintQueryType.email),
    (AppStrings.tracePhone,    Icons.phone_outlined,        OsintQueryType.phone),
    (AppStrings.traceUsername, Icons.alternate_email,       OsintQueryType.username),
    (AppStrings.traceIP,       Icons.router_outlined,       OsintQueryType.ip),
    (AppStrings.traceWebsite,  Icons.language_outlined,     OsintQueryType.website),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _result  = null;
          _error   = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runQuery(String query) async {
    if (query.trim().isEmpty) return;
    final type = _tabs[_tabController.index].$3;

    setState(() { _isLoading = true; _result = null; _error = null; });

    OsintResult result;
    switch (type) {
      case OsintQueryType.email:
        result = await OsintService.instance.checkEmail(query);
      case OsintQueryType.phone:
        result = await OsintService.instance.lookupPhone(query);
      case OsintQueryType.username:
        result = await OsintService.instance.lookupUsername(query);
      case OsintQueryType.ip:
        result = await OsintService.instance.lookupIp(query);
      case OsintQueryType.website:
        result = await OsintService.instance.lookupWebsite(query);
      default:
        result = OsintResult.error(type, query, 'Not supported yet.');
    }

    if (mounted) setState(() { _isLoading = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.traceIQTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          labelColor:     AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: AppColors.divider,
          tabs: _tabs.map((t) => Tab(
            icon:  Icon(t.$2, size: 18),
            text:  t.$1,
          )).toList(),
        ),
      ),
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.bgSecondary,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.accent, size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    AppStrings.traceDisclaimer,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OsintInputPanel(
                    type:     _tabs[_tabController.index].$3,
                    onSearch: _runQuery,
                  ),
                  const SizedBox(height: 20),
                  // Self-investigate CTA
                  _buildSelfInvestigateCta(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    Column(children: [
                      const LoadingShimmer(height: 200),
                      const SizedBox(height: 12),
                      const LoadingShimmer(height: 100),
                    ])
                  else if (_result != null)
                    OsintResultCard(result: _result!)
                  else if (_error != null)
                    AppErrorWidget(message: _error!, onRetry: null),
                ],
              ),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildSelfInvestigateCta() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.manage_search_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.investigateSelf,
                  style: TextStyle(
                    color:      AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Check what public data exists about you online.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted, size: 14),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
