import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _sentToday = 0;
  String? _lastSentDate;

  static const _androidDetails = AndroidNotificationDetails(
    'deeptruth_channel',
    'DeepTruth Alerts',
    channelDescription: 'DeepTruth daily truth checks and streak alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  // ── INIT ──────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios     = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      _initialized = true;
      await _scheduleDaily();
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  // ── SCHEDULE DAILY ────────────────────────────────────────────────
  Future<void> _scheduleDaily() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();

      await _scheduleAt(
        id:    AppConstants.notifMorning,
        hour:  8,
        min:   0,
        title: "Today's Reality Check is Ready 🔍",
        body:  "Tap to see what's fact and what's fiction today.",
      );

      await _scheduleAt(
        id:    AppConstants.notifNoon,
        hour:  12,
        min:   30,
        title: '1 Viral Claim Spreading Right Now',
        body:  'True or False? Tap to find out before you share it.',
      );

      await _scheduleAt(
        id:    AppConstants.notifBreaking,
        hour:  18,
        min:   0,
        title: 'DeepTruth Breaking Truths 📡',
        body:  'Most shared misinformation of the day — verified.',
      );
    } catch (e) {
      debugPrint('Schedule daily failed: $e');
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required int hour,
    required int min,
    required String title,
    required String body,
  }) async {
    try {
      final now     = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, min,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('_scheduleAt failed: $e');
    }
  }

  // ── STREAK REMINDER ───────────────────────────────────────────────
  Future<void> scheduleStreakReminder(int streakDays) async {
    if (!_initialized) return;
    try {
      final now       = tz.TZDateTime.now(tz.local);
      final scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 21, 0,
      );
      if (scheduled.isBefore(now)) return; // Too late for today

      await _plugin.zonedSchedule(
        AppConstants.notifStreak,
        '🔥 Your $streakDays-day streak ends in 3 hours!',
        'Open DeepTruth to keep your streak alive.',
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleStreakReminder failed: $e');
    }
  }

  // ── IMMEDIATE NOTIFICATION ────────────────────────────────────────
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastSentDate == today && _sentToday >= 3) return; // Max 3/day
    if (_lastSentDate != today) {
      _sentToday    = 0;
      _lastSentDate = today;
    }

    try {
      await _plugin.show(id, title, body, _details);
      _sentToday++;
    } catch (e) {
      debugPrint('showImmediate failed: $e');
    }
  }

  // ── PERMISSION REQUEST ────────────────────────────────────────────
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios     = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final aResult = await android?.requestNotificationsPermission() ?? true;
      final iResult = await ios?.requestPermissions(
        alert: true, badge: true, sound: true,
      ) ?? true;

      return aResult && (iResult == true);
    } catch (_) {
      return false;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.id}');
  }
}
