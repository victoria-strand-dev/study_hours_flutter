import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'study_sessions';
  static const _channelName = 'Study Sessions';
  static const _channelDesc = 'Reminders for upcoming study sessions';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request POST_NOTIFICATIONS permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Stable notification ID derived from entry id.
  int _idFor(String entryId) => entryId.hashCode.abs() % 2147483647;

  /// Schedule a 15-minute-before reminder for a single future, incomplete entry.
  Future<void> scheduleForEntry(ScheduleEntry entry) async {
    if (!_initialized) return;
    if (entry.completed) return;

    final parts = entry.startTime.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final sessionStart = tz.TZDateTime(
      tz.local,
      entry.date.year,
      entry.date.month,
      entry.date.day,
      hour,
      minute,
    );
    final notifyAt = sessionStart.subtract(const Duration(minutes: 15));
    if (notifyAt.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _idFor(entry.id),
      entry.courseName,
      'Starts in 15 min · ${entry.startTime}–${entry.endTime}',
      notifyAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the reminder for a single entry.
  Future<void> cancelForEntry(String entryId) async {
    if (!_initialized) return;
    await _plugin.cancel(_idFor(entryId));
  }

  /// Cancel all pending notifications and reschedule from the provided list.
  /// Only schedules the next 50 future, incomplete sessions (iOS limit is 64).
  Future<void> rescheduleAll(List<ScheduleEntry> entries) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();
    final future = entries.where((e) {
      if (e.completed) return false;
      final parts = e.startTime.split(':');
      if (parts.length < 2) return false;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final t = DateTime(e.date.year, e.date.month, e.date.day, h, m);
      return t.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final da = a.date.millisecondsSinceEpoch;
        final db = b.date.millisecondsSinceEpoch;
        return da != db ? da.compareTo(db) : a.startTime.compareTo(b.startTime);
      });

    for (final entry in future.take(50)) {
      await scheduleForEntry(entry);
    }
  }
}
