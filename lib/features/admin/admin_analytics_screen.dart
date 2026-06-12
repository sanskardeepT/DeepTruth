import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _topQueries = [];
  Map<String, dynamic> _vaultStats = {};
  List<Map<String, dynamic>> _feedback = [];

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final analyticsData = await FirebaseService.instance.getAdminAnalytics();
      final announcementsData = await FirebaseService.instance.getAnnouncements();
      final topQueriesData = await FirebaseService.instance.getTopQueries();
      final vaultStatsData = await FirebaseService.instance.getVaultStats();
      final feedbackData = await FirebaseService.instance.getUserFeedback();
      
      setState(() {
        _analytics = analyticsData;
        _announcements = announcementsData;
        _topQueries = topQueriesData;
        _vaultStats = vaultStatsData;
        _feedback = feedbackData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load admin operations data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseService.instance.createAnnouncement(
        title: title,
        message: message,
        priority: _selectedPriority,
      );

      _titleController.clear();
      _messageController.clear();
      _selectedPriority = 'Medium';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing announcement: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text(
            'Founder Command Center',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
          ),
          backgroundColor: AppColors.bgSecondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accent, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              onPressed: _isLoading ? null : _fetchData,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            tabs: [
              Tab(text: 'METRICS'),
              Tab(text: 'TOP QUERIES'),
              Tab(text: 'VAULT ANALYTICS'),
              Tab(text: 'FEEDBACK & BULLETINS'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : TabBarView(
                children: [
                  _buildMetricsTab(),
                  _buildTopQueriesTab(),
                  _buildVaultAnalyticsTab(),
                  _buildFeedbackAndBulletinsTab(),
                ],
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 1: METRICS & SYSTEM HEALTH
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMetricsTab() {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('OPERATIONAL METRICS'),
            const SizedBox(height: 12),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('SYSTEM HEALTH & LIMITS'),
            const SizedBox(height: 12),
            _buildSystemHealthSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('FEATURE USAGE BREAKDOWN'),
            const SizedBox(height: 12),
            _buildFeatureUsageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final totalUsers = _analytics['totalUsers'] ?? 0;
    final dau = _analytics['dau'] ?? 0;
    final totalScans = _analytics['totalScans'] ?? 0;
    final revenue = _analytics['revenue'] ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard('Total Users', '$totalUsers', Icons.people_rounded, AppColors.accent),
        _buildMetricCard('Daily Active (DAU)', '$dau', Icons.offline_bolt_rounded, AppColors.success),
        _buildMetricCard('Total Scans', '$totalScans', Icons.qr_code_scanner_rounded, AppColors.warning),
        _buildMetricCard('Est. Revenue', '\$${revenue.toStringAsFixed(2)}', Icons.monetization_on_rounded, AppColors.success),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scaleXY(begin: 0.95, end: 1.0, duration: 150.ms);
  }

  Widget _buildSystemHealthSection() {
    final scanLimit = FirebaseService.instance.dailyScanLimit;
    final isMaintenance = FirebaseService.instance.maintenanceMode;
    final adsEnabled = FirebaseService.instance.showAds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildHealthRow('Firebase Cloud Database', 'CONNECTED', AppColors.success),
          const Divider(color: AppColors.divider),
          _buildHealthRow('AdMob Initialization', adsEnabled ? 'ACTIVE / RUNNING' : 'DISABLED', adsEnabled ? AppColors.success : AppColors.danger),
          const Divider(color: AppColors.divider),
          _buildHealthRow('Remote System Mode', isMaintenance ? 'MAINTENANCE ACTIVE ⚠️' : 'ONLINE', isMaintenance ? AppColors.warning : AppColors.success),
          const Divider(color: AppColors.divider),
          _buildHealthRow('User Daily Scan Limit', '$scanLimit check scans / day', AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageSection() {
    final Map<dynamic, dynamic> rawUsage = _analytics['mostUsedFeatures'] ?? {};
    final usage = Map<String, int>.from(rawUsage.map((k, v) => MapEntry(k.toString(), v as int)));

    if (usage.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            'No usage logs found.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    final maxVal = usage.values.fold<int>(0, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: usage.entries.map((entry) {
          final percentage = maxVal > 0 ? (entry.value / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${entry.value} checks',
                      style: const TextStyle(color: AppColors.accent, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    color: AppColors.accent,
                    backgroundColor: AppColors.bgSecondary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 2: TOP QUERIES INTELLIGENCE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTopQueriesTab() {
    if (_topQueries.isEmpty) {
      return const Center(
        child: Text('No historical queries registered.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topQueries.length,
      itemBuilder: (context, index) {
        final query = _topQueries[index];
        final content = query['content'] ?? 'Empty Content';
        final inputType = query['inputType'] ?? 'unknown';
        final count = query['scanCount'] ?? 0;

        IconData icon;
        switch (inputType) {
          case 'image': icon = Icons.image_rounded; break;
          case 'video': icon = Icons.videocam_rounded; break;
          case 'url': icon = Icons.link_rounded; break;
          default: icon = Icons.chat_bubble_outline_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListTile(
            leading: Icon(icon, color: AppColors.accent, size: 20),
            title: Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Type: ${inputType.toUpperCase()}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$count scans',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 3: EVIDENCE VAULT ANALYTICS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildVaultAnalyticsTab() {
    final int total = _vaultStats['totalChecks'] ?? 0;
    final int hits = _vaultStats['cacheHits'] ?? 0;
    final int repeated = _vaultStats['repeatedMisinfoCount'] ?? 0;
    final double rate = total > 0 ? (hits / total) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('EVIDENCE VAULT STATISTICS'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildStatValueRow('Total Verifications Logged', '$total'),
                const Divider(color: AppColors.divider),
                _buildStatValueRow('Vault Cache Hits / Reuses', '$hits'),
                const Divider(color: AppColors.divider),
                _buildStatValueRow('Vault Cache Hit Rate', '${rate.toStringAsFixed(1)}%'),
                const Divider(color: AppColors.divider),
                _buildStatValueRow('Repeated Misinformation Blocks', '$repeated', isWarning: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('ANALYTIC BRIEF'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Text(
              'The DeepTruth Evidence Vault prevents duplicate API computation costs. When users upload media or claims, their cryptographic hashes are indexed. Hits indicate reuses, and repeated misinformation indicators count block triggers against known debunked narratives.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatValueRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 4: FEEDBACK & BULLETIN CENTER
  // ══════════════════════════════════════════════════════════════════
  Widget _buildFeedbackAndBulletinsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('BULLETIN PUBLISHING'),
          const SizedBox(height: 12),
          _buildPublishForm(),
          const SizedBox(height: 24),
          _buildSectionTitle('LIVE BULLETINS'),
          const SizedBox(height: 12),
          _buildAnnouncementsList(),
          const SizedBox(height: 24),
          _buildSectionTitle('USER FEEDBACK LOGS'),
          const SizedBox(height: 12),
          _buildFeedbackList(),
        ],
      ),
    );
  }

  Widget _buildPublishForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Title', 'Enter bulletin title...', _titleController),
          const SizedBox(height: 12),
          _buildTextField('Message', 'Enter bulletin description...', _messageController, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Priority: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              ...['Low', 'Medium', 'High'].map((priority) {
                final isSelected = _selectedPriority == priority;
                Color chipColor = AppColors.info;
                if (priority == 'High') chipColor = AppColors.danger;
                if (priority == 'Medium') chipColor = AppColors.warning;
                if (priority == 'Low') chipColor = AppColors.success;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      priority,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: chipColor,
                    backgroundColor: AppColors.bgSecondary,
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(color: isSelected ? chipColor : AppColors.divider),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPriority = priority);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text('Publish Bulletin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('No active bulletins.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _announcements.length > 3 ? 3 : _announcements.length,
      itemBuilder: (context, index) {
        final item = _announcements[index];
        final title = item['title'] ?? 'No Title';
        final priority = item['priority'] ?? 'Medium';

        Color color = AppColors.info;
        if (priority == 'High') color = AppColors.danger;
        if (priority == 'Medium') color = AppColors.warning;
        if (priority == 'Low') color = AppColors.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackList() {
    if (_feedback.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('No user feedback logs.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _feedback.length,
      itemBuilder: (context, index) {
        final item = _feedback[index];
        final id = item['reportId'] ?? 'DT-UNKNOWN';
        final rating = item['userFeedback'] ?? 'helpful';
        final comment = item['userComment'] ?? '';
        final isHelpful = rating == 'helpful';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id,
                    style: const TextStyle(color: AppColors.textAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    isHelpful ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                    color: isHelpful ? AppColors.success : AppColors.danger,
                    size: 14,
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textAccent,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}
