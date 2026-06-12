import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_service.dart';
import '../../admin/admin_analytics_screen.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _geminiController = TextEditingController();
  final _newsApiController = TextEditingController();
  final _gNewsController = TextEditingController();
  final _factCheckController = TextEditingController();
  final _hibpController = TextEditingController();

  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        _geminiController.text = box.get('custom_key_gemini') ?? '';
        _newsApiController.text = box.get('custom_key_news_api') ?? '';
        _gNewsController.text = box.get('custom_key_g_news') ?? '';
        _factCheckController.text = box.get('custom_key_google_fact_check') ?? '';
        _hibpController.text = box.get('custom_key_hibp') ?? '';
      }
    } catch (_) {}
  }

  Future<void> _saveKeys() async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        await box.put('custom_key_gemini', _geminiController.text.trim());
        await box.put('custom_key_news_api', _newsApiController.text.trim());
        await box.put('custom_key_g_news', _gNewsController.text.trim());
        await box.put('custom_key_google_fact_check', _factCheckController.text.trim());
        await box.put('custom_key_hibp', _hibpController.text.trim());

        // Re-initialize Gemini service
        GeminiService.instance.initialize();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Keys saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testMessage = 'Failed to save: $e';
          _testSuccess = false;
        });
      }
    }
  }

  Future<void> _testGeminiKey() async {
    final key = _geminiController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testMessage = 'Please enter a Gemini API Key first.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );
      final response = await model.generateContent([
        Content.text('Say "Key verified successfully!" in exactly 1 line.'),
      ]).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = response.text != null;
          _testMessage = response.text?.trim() ?? 'No response from model.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testMessage = 'Test failed: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _newsApiController.dispose();
    _gNewsController.dispose();
    _factCheckController.dispose();
    _hibpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('⚙️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'API Key Settings',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Bring your own keys to enable live AI & network features. Leaving fields empty will use system fallback default values.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 20),
              _buildKeyField(
                label: 'Gemini API Key',
                hint: 'AI features, fact-checks, & chat',
                controller: _geminiController,
                isPassword: true,
                suffix: TextButton(
                  onPressed: _isTesting ? null : _testGeminiKey,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  child: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Text('Test Key'),
                ),
              ),
              if (_testMessage != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_testSuccess ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _testMessage!,
                    style: TextStyle(
                      color: _testSuccess ? AppColors.success : AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildKeyField(
                label: 'NewsAPI Key',
                hint: 'Fills general news in Trust Feed',
                controller: _newsApiController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildKeyField(
                label: 'GNews API Key',
                hint: 'Fallback Trust Feed provider',
                controller: _gNewsController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildKeyField(
                label: 'Google Fact Check Explorer Key',
                hint: 'Official source database lookup',
                controller: _factCheckController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildKeyField(
                label: 'HaveIBeenPwned API Key',
                hint: 'Advanced OSINT email breach lookup',
                controller: _hibpController,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAnalyticsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent),
                  label: const Text(
                    'Access Founder Ops Portal',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.accent, width: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveKeys,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save & Apply',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              if (suffix != null) suffix,
            ],
          ),
        ),
      ],
    );
  }
}
