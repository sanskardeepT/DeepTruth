import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../app.dart';
import 'widgets/daily_reality_card.dart';
import 'widgets/quick_action_chips.dart';
import 'widgets/trending_checks_list.dart';
import 'widgets/settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.bgCard,
        onRefresh: () => context.read<AppProvider>().refreshHomeData(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOfflineBanner(context),
                  _buildAnnouncementBanner(context),
                  const SizedBox(height: 16),
                  const DailyRealityCard(),
                  const SizedBox(height: 20),
                  const QuickActionChips(),
                  const SizedBox(height: 20),
                  const TrendingChecksList(),
                  const SizedBox(height: 16),
                  const AdBannerWidget(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.bgPrimary,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/deeptruth_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color:      AppColors.textPrimary,
                    fontSize:   18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'In a world of lies, let DeepTruth be your eyes',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          tooltip: 'API Keys Settings',
          onPressed: () => SettingsDialog.show(context),
        ),
        Consumer<AppProvider>(
          builder: (context, appProvider, __) => PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded, color: AppColors.textPrimary),
            color: AppColors.bgCard,
            onSelected: (langCode) {
              appProvider.changeLocale(langCode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'en',
                child: Text('English', style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'hi',
                child: Text('हिंदी (Hindi)', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Consumer<StreakProvider>(
            builder: (context, streak, __) => GestureDetector(
              onTap: () {
                // Switch to Streak tab (index 5)
                context.findAncestorStateOfType<MainShellState>()?.setIndex(5);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${streak.streak.currentStreak}',
                      style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize:   12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, app, __) {
        if (app.isOnline) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.errorNetwork,
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.3);
      },
    );
  }

  Widget _buildAnnouncementBanner(BuildContext context) {
    final bannerText = FirebaseService.instance.announcementBanner;
    if (bannerText.isEmpty) return const SizedBox.shrink();

    bool isDismissed = false;
    return StatefulBuilder(
      builder: (context, setState) {
        if (isDismissed) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.15),
                AppColors.primaryLight.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📢', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANNOUNCEMENT',
                      style: TextStyle(
                        color: AppColors.textAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bannerText,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                onPressed: () {
                  setState(() {
                    isDismissed = true;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.2);
      },
    );
  }
}
