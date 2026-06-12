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
      setState(() {
        _analytics = analyticsData;
        _announcements = announcementsData;
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
      // Refresh list
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text(
          'Founder Ops Portal',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.bgCard,
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('OPERATIONAL METRICS'),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('FEATURE USAGE BREAKDOWN'),
                    const SizedBox(height: 12),
                    _buildFeatureUsageSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('ANNOUNCEMENT CENTER'),
                    const SizedBox(height: 12),
                    _buildPublishForm(),
                    const SizedBox(height: 16),
                    _buildAnnouncementsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ).animate().fadeIn(duration: 300.ms);
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
        _buildMetricCard('Daily Active', '$dau', Icons.offline_bolt_rounded, AppColors.success),
        _buildMetricCard('Total Scans', '$totalScans', Icons.qr_code_scanner_rounded, AppColors.warning),
        _buildMetricCard('Est. Revenue', '\$${revenue.toStringAsFixed(2)}', Icons.monetization_on_rounded, AppColors.truthMostly),
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
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 200.ms, curve: Curves.easeOut);
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
            'No usage data recorded yet.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                      '${entry.value} scans',
                      style: const TextStyle(color: AppColors.accent, fontSize: 12),
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
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
          const Text(
            'Publish Broadcast Announcement',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField('Title', 'Enter announcement title...', _titleController),
          const SizedBox(height: 12),
          _buildTextField('Message', 'Enter announcement description...', _messageController, maxLines: 3),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Priority: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
                      'Publish Now',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          child: Text(
            'No announcements found in registry.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE BROADCAST REGISTRY',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _announcements.length,
          itemBuilder: (context, index) {
            final item = _announcements[index];
            final title = item['title'] ?? 'No Title';
            final message = item['message'] ?? 'No Message';
            final priority = item['priority'] ?? 'Medium';
            
            // Format timestamp nicely
            String timeStr = 'Just now';
            final ts = item['timestamp'];
            if (ts != null) {
              if (ts is DateTime) {
                timeStr = ts.toLocal().toString().substring(0, 16);
              } else {
                // Cloud Firestore Timestamp
                try {
                  timeStr = ts.toDate().toLocal().toString().substring(0, 16);
                } catch (_) {}
              }
            }

            Color priorityColor = AppColors.info;
            if (priority == 'High') priorityColor = AppColors.danger;
            if (priority == 'Medium') priorityColor = AppColors.warning;
            if (priority == 'Low') priorityColor = AppColors.success;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ).animate().slideX(begin: 0.1, duration: 150.ms);
          },
        ),
      ],
    );
  }
}
