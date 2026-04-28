import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppData _data;
  String? _userEmail;
  String? _firebaseUid;

  AppState(AppData data, String? email, {String? firebaseUid})
      : _data = data,
        _userEmail = email,
        _firebaseUid = firebaseUid;

  AppData get data => _data;
  String? get userEmail => _userEmail;
  String? get firebaseUid => _firebaseUid;

  List<Course> get courses => _data.courses;
  List<ScheduleEntry> get schedule => _data.schedule;
  int get semesterCredits => _data.semesterCredits;
  int get semesterWeeks => _data.semesterWeeks;
  DateTime? get semesterStartDate => _data.semesterStartDate;
  int? get currentSemesterWeek => _data.currentSemesterWeek;
  int? get weeksRemaining => _data.weeksRemaining;
  double get totalCourseCredits => _data.totalCourseCredits;

  // ─── Persist ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    await StorageService.instance.saveAppData(_data);
    if (_firebaseUid != null) {
      // Fire-and-forget — failure is non-critical (local cache stays intact)
      StorageService.instance.saveToFirestore(_firebaseUid!, _data);
    }
  }

  // ─── Semester settings ─────────────────────────────────────────────────────

  Future<void> updateSemesterSettings(
      int credits, int weeks, DateTime? startDate,
      {bool clearStartDate = false}) async {
    _data = _data.copyWith(
      semesterCredits: credits,
      semesterWeeks: weeks,
      semesterStartDate: startDate,
      clearStartDate: clearStartDate,
    );
    await _save();
    notifyListeners();
  }

  // ─── Courses ───────────────────────────────────────────────────────────────

  Future<void> addCourse(Course course) async {
    final updated = List<Course>.from(_data.courses)..add(course);
    _data = _data.copyWith(courses: updated);
    await _save();
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    final updated =
        _data.courses.map((c) => c.id == course.id ? course : c).toList();
    _data = _data.copyWith(courses: updated);
    await _save();
    notifyListeners();
  }

  Future<void> deleteCourse(String id) async {
    final updatedCourses = _data.courses.where((c) => c.id != id).toList();
    final updatedSchedule =
        _data.schedule.where((s) => s.courseId != id).toList();
    _data = _data.copyWith(courses: updatedCourses, schedule: updatedSchedule);
    await _save();
    notifyListeners();
  }

  // ─── Schedule ──────────────────────────────────────────────────────────────

  Future<void> addScheduleEntry(ScheduleEntry entry) async {
    final updated = List<ScheduleEntry>.from(_data.schedule)..add(entry);
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
    NotificationService.instance.scheduleForEntry(entry);
  }

  Future<void> addScheduleEntries(List<ScheduleEntry> entries) async {
    final updated = List<ScheduleEntry>.from(_data.schedule)..addAll(entries);
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
    NotificationService.instance.rescheduleAll(_data.schedule);
  }

  Future<void> toggleEntryComplete(String id) async {
    final updated = _data.schedule.map((s) {
      if (s.id == id) return s.copyWith(completed: !s.completed);
      return s;
    }).toList();
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
    final entry = _data.schedule.firstWhere((s) => s.id == id);
    if (entry.completed) {
      NotificationService.instance.cancelForEntry(id);
    } else {
      NotificationService.instance.scheduleForEntry(entry);
    }
  }

  Future<void> deleteScheduleEntry(String id) async {
    final updated = _data.schedule.where((s) => s.id != id).toList();
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
    NotificationService.instance.cancelForEntry(id);
  }

  Future<void> updateScheduleEntry(ScheduleEntry updated) async {
    final list =
        _data.schedule.map((s) => s.id == updated.id ? updated : s).toList();
    _data = _data.copyWith(schedule: list);
    await _save();
    notifyListeners();
    NotificationService.instance.cancelForEntry(updated.id);
    NotificationService.instance.scheduleForEntry(updated);
  }

  Future<void> updateFutureWeekdaySessions(
      String courseId, int weekday, DateTime fromDate,
      String newStart, String newEnd) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final list = _data.schedule.map((s) {
      if (s.courseId != courseId) return s;
      if (!s.id.contains('_auto_')) return s;
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      if (s.date.weekday != weekday) return s;
      if (d.isBefore(from)) return s;
      return s.copyWith(startTime: newStart, endTime: newEnd);
    }).toList();
    _data = _data.copyWith(schedule: list);
    await _save();
    notifyListeners();
    NotificationService.instance.rescheduleAll(_data.schedule);
  }

  Future<void> removeAutoScheduleForCourses(List<String> courseIds) async {
    final ids = courseIds.toSet();
    final updated = _data.schedule
        .where((s) => !(ids.contains(s.courseId) && s.id.contains('_auto_')))
        .toList();
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
    NotificationService.instance.rescheduleAll(_data.schedule);
  }

  // ─── Computed ──────────────────────────────────────────────────────────────

  double completedHoursForCourse(String courseId) {
    double total = 0;
    for (final e in _data.schedule) {
      if (e.courseId == courseId && e.completed) {
        total += _parseDuration(e.startTime, e.endTime);
      }
    }
    return total;
  }

  static double _parseDuration(String start, String end) {
    double toH(String t) {
      final p = t.split(':');
      if (p.length < 2) return 0;
      return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
    }
    return (toH(end) - toH(start)).clamp(0.0, 24.0);
  }

  int? weeksRemainingForCourse(Course course) {
    if (course.examDate != null) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final examOnly = DateTime(
          course.examDate!.year, course.examDate!.month, course.examDate!.day);
      final diff = examOnly.difference(todayOnly).inDays;
      if (diff <= 0) return 0;
      return ((diff - 1) ~/ 7) + 1;
    }
    return weeksRemaining;
  }

  double? requiredHoursForCourse(Course course) {
    if (semesterCredits <= 0 || semesterWeeks <= 0 || course.credits <= 0) {
      return null;
    }
    final m = gradeMultiplier(course.targetGrade);
    if (m == null) return null;
    return (course.credits / semesterCredits) * 37.5 * semesterWeeks * m;
  }

  // ─── Dynamic weekly recalculation ─────────────────────────────────────────

  /// Effective completed hours for a course.
  /// In catch-up mode: adds hoursStudiedSoFar (pre-app hours) to calendar hours.
  /// This is the single source of truth — use everywhere instead of
  /// completedHoursForCourse when displaying progress to the user.
  double effectiveCompletedHours(Course course) {
    final fromSchedule = completedHoursForCourse(course.id);
    return course.catchUpMode
        ? fromSchedule + course.hoursStudiedSoFar
        : fromSchedule;
  }

  /// Total hours required for a given grade — uses the semester-aware formula
  /// so it is consistent with requiredHoursForCourse (used by the progress bar).
  /// Falls back to 25h/credit (ECTS standard) when semester settings are absent.
  double targetHoursForGrade(Course course, String grade) {
    final m = gradeMultiplier(grade) ?? 0.0;
    if (m == 0) return 0;
    if (semesterCredits > 0 && semesterWeeks > 0 && course.credits > 0) {
      return (course.credits / semesterCredits) * 37.5 * semesterWeeks * m;
    }
    return course.credits * 25 * m; // fallback
  }

  /// Remaining hours needed to reach the target grade from now.
  double remainingHours(Course course) {
    final target = targetHoursForGrade(course, course.targetGrade);
    final done   = effectiveCompletedHours(course);
    return (target - done).clamp(0.0, double.infinity);
  }

  // How many hours/week are needed FROM NOW based on actual progress and time left.
  // Returns null when no exam date is set or target is already met.
  double? dynamicWeeklyHours(Course course) {
    final weeksLeft = weeksRemainingForCourse(course);
    if (weeksLeft == null || weeksLeft <= 0) return null;
    final rem = remainingHours(course);
    if (rem <= 0) return 0;
    return rem / weeksLeft;
  }

  // Next grade above target (A has no next). Returns null if already at A or at F.
  String? nextGrade(Course course) {
    const order = ['F', 'E', 'D', 'C', 'B', 'A'];
    final idx = order.indexOf(course.targetGrade.toUpperCase());
    if (idx < 0 || idx >= order.length - 1) return null;
    return order[idx + 1];
  }

  // Returns the next achievable grade if the user's CURRENT weekly pace would
  // reach that threshold within weeks remaining. Returns null if not possible.
  String? achievableUpgradeGrade(Course course) {
    final weeksLeft = weeksRemainingForCourse(course);
    if (weeksLeft == null || weeksLeft <= 0) return null;
    final next = nextGrade(course);
    if (next == null) return null;

    // Average pace: completed hours / weeks elapsed since first session.
    final allDone = _data.schedule
        .where((e) => e.courseId == course.id && e.completed)
        .toList();
    if (allDone.isEmpty) return null;

    final firstDate = allDone.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final today = DateTime.now();
    final weeksElapsed = today.difference(firstDate).inDays / 7.0;
    if (weeksElapsed < 0.5) return null; // not enough data

    final completedH = effectiveCompletedHours(course);
    final weeklyPace = completedH / weeksElapsed;
    if (weeklyPace <= 0) return null;

    final projected = completedH + weeklyPace * weeksLeft;
    final nextTarget = targetHoursForGrade(course, next);
    return projected >= nextTarget ? next : null;
  }

  int get studyStreak {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = todayOnly.subtract(Duration(days: i));
      final dayEntries = entriesForDay(day);
      if (dayEntries.isEmpty) continue;
      if (dayEntries.any((e) => e.completed)) {
        streak++;
      } else if (i == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  Color courseColorOf(String courseId) {
    final idx = _data.courses.indexWhere((c) => c.id == courseId);
    if (idx == -1) return const Color(0xFF2D8FC4);
    final course = _data.courses[idx];
    if (course.color != 0) return Color(course.color);
    return Color(CourseColors.presets[idx % CourseColors.presets.length]);
  }

  List<ScheduleEntry> entriesForDay(DateTime day) {
    return _data.schedule.where((s) {
      return s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Set<DateTime> get daysWithEntries {
    return _data.schedule
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();
  }

  // ─── User / Auth ───────────────────────────────────────────────────────────

  Future<void> saveUserEmail(String email) async {
    _userEmail = email;
    await StorageService.instance.saveUserEmail(email);
    notifyListeners();
  }

  /// Called after successful Firebase login/register.
  Future<void> setFirebaseUser(String uid, String email) async {
    _firebaseUid = uid;
    _userEmail = email;
    await StorageService.instance.saveUserEmail(email);

    try {
      final cloudData = await StorageService.instance.loadFromFirestore(uid);
      if (cloudData != null) {
        // Existing user — load cloud data
        _data = cloudData;
        await StorageService.instance.saveAppData(_data);
      } else {
        // New user — push local data to Firestore
        await StorageService.instance.saveToFirestore(uid, _data);
      }
    } catch (_) {
      // Cloud sync failed — continue with local data
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await StorageService.instance.clearAll();
    _data = AppData();
    _userEmail = null;
    _firebaseUid = null;
    notifyListeners();
  }

  /// Deletes the user's Firestore document. Call before deleting the Auth account.
  /// Throws if Firestore deletion fails.
  Future<void> deleteFirestoreData() async {
    if (_firebaseUid == null) return;
    await StorageService.instance.deleteUserData(_firebaseUid!);
  }

  /// Clears local state after the Auth account has been deleted.
  Future<void> clearLocalAfterDelete() async {
    await StorageService.instance.clearAll();
    _data = AppData();
    _userEmail = null;
    _firebaseUid = null;
    notifyListeners();
  }

  /// Legacy — kept for compatibility.
  Future<void> deleteAccount() async {
    await deleteFirestoreData();
    await FirebaseAuth.instance.currentUser?.delete();
    await clearLocalAfterDelete();
  }
}

// ─── Provider Widget ──────────────────────────────────────────────────────────

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
