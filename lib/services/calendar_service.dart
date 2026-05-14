import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

class CalendarResult {
  final bool success;
  final String? errorMessage;
  const CalendarResult.ok()
      : success = true,
        errorMessage = null;
  const CalendarResult.err(this.errorMessage) : success = false;
}

class CalendarService {
  static final CalendarService instance = CalendarService._();
  CalendarService._();

  final _plugin = DeviceCalendarPlugin();
  bool _tzInitialized = false;

  void _ensureTz() {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    _tzInitialized = true;
  }

  Future<bool> _requestPermission() async {
    var result = await _plugin.requestPermissions();
    return result.data == true;
  }

  Future<String?> _calendarId() async {
    final result = await _plugin.retrieveCalendars();
    final calendars = result.data ?? [];
    final study = calendars
        .where((c) => !(c.isReadOnly ?? true))
        .where((c) => c.name?.toLowerCase() == 'studyhours')
        .firstOrNull;
    if (study != null) return study.id;
    return calendars.where((c) => !(c.isReadOnly ?? true)).firstOrNull?.id;
  }

  tz.TZDateTime _toTZ(DateTime date, String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return tz.TZDateTime(tz.local, date.year, date.month, date.day, h, m);
  }

  Future<CalendarResult> addEvent(ScheduleEntry entry) async {
    _ensureTz();
    if (!await _requestPermission()) {
      return const CalendarResult.err(
          'Calendar permission denied — enable it in Settings');
    }
    final calId = await _calendarId();
    if (calId == null) {
      return const CalendarResult.err(
          'No calendar found — add an account in the Calendar app first');
    }

    final event = Event(
      calId,
      title: '${entry.courseName} – Study',
      start: _toTZ(entry.date, entry.startTime),
      end: _toTZ(entry.date, entry.endTime),
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result?.data?.isNotEmpty == true) return const CalendarResult.ok();
    final errors = result?.errors.map((e) => e.errorMessage).join(', ') ?? '';
    return CalendarResult.err(
        errors.isNotEmpty ? errors : 'Failed to create event');
  }

  Future<(int, String?)> addEvents(List<ScheduleEntry> entries) async {
    _ensureTz();
    if (!await _requestPermission()) {
      return (0, 'Calendar permission denied — enable it in Settings');
    }
    final calId = await _calendarId();
    if (calId == null) {
      return (
        0,
        'No calendar found — add an account in the Calendar app first'
      );
    }

    int count = 0;
    for (final entry in entries) {
      final event = Event(
        calId,
        title: '${entry.courseName} – Study',
        start: _toTZ(entry.date, entry.startTime),
        end: _toTZ(entry.date, entry.endTime),
      );
      final result = await _plugin.createOrUpdateEvent(event);
      if (result?.data?.isNotEmpty == true) count++;
    }
    return (count, null);
  }
}
