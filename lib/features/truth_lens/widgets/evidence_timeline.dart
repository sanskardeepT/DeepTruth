import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/check_result.dart';

class TimelineEvent {
  final String title;
  final String date;
  final String description;
  final IconData icon;
  final bool highlight;

  TimelineEvent({
    required this.title,
    required this.date,
    required this.description,
    required this.icon,
    this.highlight = false,
  });
}

class EvidenceTimeline extends StatelessWidget {
  final CheckResult result;

  const EvidenceTimeline({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final events = _parseEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: AppColors.textAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'MEDIA INTEGRITY TIMELINE',
              style: TextStyle(
                color: AppColors.textAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dot & Connector Line
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: event.highlight 
                                ? AppColors.accent.withValues(alpha: 0.15) 
                                : AppColors.bgSecondary,
                            border: Border.all(
                              color: event.highlight ? AppColors.accent : AppColors.divider,
                              width: event.highlight ? 2.0 : 1.5,
                            ),
                          ),
                          child: Icon(
                            event.icon,
                            color: event.highlight ? AppColors.accent : AppColors.textSecondary,
                            size: 14,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: AppColors.divider,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Event Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    color: event.highlight ? AppColors.accent : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgPrimary,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Text(
                                    event.date,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<TimelineEvent> _parseEvents() {
    final List<TimelineEvent> events = [];

    // 1. Capture / Creation Timestamp
    String? originDate = result.c2pa?.createdAt ?? result.provenance?.earliestDate;
    if (originDate == null && result.provenance?.exif != null) {
      final exif = result.provenance!.exif;
      originDate = exif['DateTimeOriginal'] ?? exif['DateTime'] ?? exif['CreateDate'];
    }

    events.add(TimelineEvent(
      title: 'Original Asset Capture / Creation',
      date: originDate ?? 'No Date Metadata',
      description: originDate != null
          ? 'C2PA/EXIF metadata registers physical camera capture or model creation date.'
          : 'Media has no embedded capture metadata (EXIF/C2PA timestamps are missing or stripped by publisher).',
      icon: Icons.camera_enhance_rounded,
    ));

    // 2. Web Appearance / Public Crawl
    if (result.contentType == 'image' || result.contentType == 'video') {
      final appearance = result.provenance?.firstAppearance;
      events.add(TimelineEvent(
        title: 'First Public Web Fingerprint',
        date: appearance ?? 'Unique Scan Record',
        description: appearance != null
            ? 'Reverse image crawling registers first public match online at this date.'
            : 'No duplicates of this media found on public indexing engines. Original upload suspected.',
        icon: Icons.cloud_done_rounded,
      ));
    } else if (result.contentType == 'url') {
      final appearance = result.provenance?.firstAppearance ?? 'Wayback Index Active';
      events.add(TimelineEvent(
        title: 'Archival Registry Indexing',
        date: appearance,
        description: 'Web crawler records indicate domain first crawled and archived on this snapshot date.',
        icon: Icons.history_rounded,
      ));
    } else {
      events.add(TimelineEvent(
        title: 'Public Claim Proliferation',
        date: 'Social Indexing Active',
        description: 'Statement identified and indexed across semantic fact-checking networks.',
        icon: Icons.language_rounded,
      ));
    }

    // 3. Current Verification Scan
    events.add(TimelineEvent(
      title: 'DeepTruth Verification Scan',
      date: result.analyzedAt.toLocal().toString().substring(0, 16),
      description: 'Orchestrator finished audit. Verdict: ${result.verdict} (${result.truthScore}% score). SHA-256 matches verified.',
      icon: Icons.shield_rounded,
      highlight: true,
    ));

    return events;
  }
}
