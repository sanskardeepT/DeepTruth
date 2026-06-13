import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/check_provider.dart';
import 'core/providers/news_provider.dart';
import 'core/providers/streak_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/utils/version_utils.dart';
import 'features/home/home_screen.dart';
import 'features/home/widgets/update_screens.dart';
import 'features/truth_lens/truth_lens_screen.dart';
import 'features/trust_feed/trust_feed_screen.dart';
import 'features/trace_iq/trace_iq_screen.dart';
import 'features/ask_iq/ask_iq_screen.dart';
import 'features/streak/streak_screen.dart';
import 'l10n/app_localizations.dart';

class DeepTruthApp extends StatelessWidget {
  const DeepTruthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CheckProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()..initialize()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'DeepTruth',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: appProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: !appProvider.isInitialized
                ? const Scaffold(
                    backgroundColor: AppColors.bgPrimary,
                    body: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                : FirebaseService.instance.emergencyShutdown
                    ? EmergencyShutdownScreen(message: FirebaseService.instance.emergencyMessage)
                    : FirebaseService.instance.maintenanceMode
                        ? const MaintenanceScreen()
                        : VersionUtils.isVersionOlder(AppConstants.appVersion, FirebaseService.instance.requiredVersion)
                            ? const ForceUpdateScreen()
                            : const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final Map<int, Widget> _builtScreens = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyConsent();
      _checkSoftUpdate();
    });
  }

  void _checkPrivacyConsent() {
    try {
      if (!Hive.isBoxOpen(AppConstants.boxSettings)) return;
      final box = Hive.box<String>(AppConstants.boxSettings);
      final accepted = box.get('privacy_consent_accepted');
      if (accepted == 'true') return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip_rounded, color: AppColors.accent, size: 24),
              SizedBox(width: 8),
              Text('Privacy & Data Notice',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DeepTruth collects anonymous usage analytics, crash reports, and verification data to improve the service.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                'We comply with GDPR (EU) and DPDP Act (India). Your data is never sold to third parties.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                'By continuing, you agree to our Privacy Policy and Terms of Service. You can review these in Settings → Legal Center.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _PrivacyPolicyStub(),
                  ),
                );
              },
              child: const Text('Read Policy', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                box.put('privacy_consent_accepted', 'true');
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bgPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('I Accept'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  void _checkSoftUpdate() {
    final current = AppConstants.appVersion;
    final recommended = FirebaseService.instance.recommendedVersion;
    if (VersionUtils.isVersionOlder(current, recommended)) {
      SoftUpdateDialog.show(context, changelog: FirebaseService.instance.updateChangelog);
    }
  }

  void setIndex(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  Widget _buildScreen(int index) {
    return _builtScreens.putIfAbsent(index, () {
      switch (index) {
        case 0: return const HomeScreen();
        case 1: return const TruthLensScreen();
        case 2: return const TrustFeedScreen();
        case 3: return const TraceIQScreen();
        case 4: return const AskIQScreen();
        case 5: return const StreakScreen();
        default: return const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(6, (i) {
          // Only build visited screens; unvisited get an empty placeholder
          if (_builtScreens.containsKey(i) || i == _currentIndex) {
            return _buildScreen(i);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (mounted) setState(() => _currentIndex = i);
        },
        backgroundColor: const Color(0xFF141830),
        indicatorColor: const Color(0xFF00D4FF).withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF00D4FF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy_rounded, color: Color(0xFF00D4FF)),
            label: 'Truth Lens',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed_rounded, color: Color(0xFF00D4FF)),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search_rounded, color: Color(0xFF00D4FF)),
            label: 'TraceIQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF00D4FF)),
            label: 'AskIQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded, color: Color(0xFF00D4FF)),
            label: 'Streak',
          ),
        ],
      ),
    );
  }
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    await context.read<AppProvider>().checkMaintenanceStatus();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Upgrades in Progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'DeepTruth is undergoing essential database and forensic engine upgrades. We will be back shortly with faster verification speeds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Action Button
              SizedBox(
                width: 180,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Retry Connection',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal privacy policy display for first-launch consent flow.
class _PrivacyPolicyStub extends StatelessWidget {
  const _PrivacyPolicyStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Privacy Policy',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DeepTruth Privacy Policy',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(
              'Last updated: June 2026\n\n'
              '1. DATA COLLECTION\n'
              'We collect anonymous usage analytics (Firebase Analytics), crash reports (Firebase Crashlytics), '
              'and verification data (claims, URLs, images you submit for fact-checking). '
              'We do not collect your name, email, phone number, or any personally identifiable information.\n\n'
              '2. DATA USAGE\n'
              'Your data is used exclusively to:\n'
              '• Improve verification accuracy\n'
              '• Track app performance and crashes\n'
              '• Power the Evidence Vault (de-duplication of scanned content)\n'
              '• Display aggregated analytics in the admin dashboard\n\n'
              '3. DATA SHARING\n'
              'We do NOT sell, rent, or share your data with third parties. '
              'External APIs (VirusTotal, URLScan, Google Fact Check) receive only the content you explicitly submit for scanning.\n\n'
              '4. DATA RETENTION\n'
              'Verification records are retained indefinitely in the Evidence Vault for community benefit. '
              'You can request deletion by contacting support.\n\n'
              '5. GDPR & DPDP COMPLIANCE\n'
              'Users in the EU have the right to access, rectify, and delete their data under GDPR. '
              'Users in India have equivalent rights under the Digital Personal Data Protection Act, 2023.\n\n'
              '6. ADVERTISING\n'
              'We use Google AdMob for monetization. AdMob may collect device identifiers for ad personalization. '
              'You can opt out of personalized ads in your device settings.\n\n'
              '7. CONTACT\n'
              'For privacy inquiries, contact: privacy@deeptruth.app',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
