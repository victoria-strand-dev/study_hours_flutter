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

  Future<void> _save() async {
    await StorageService.instance.saveAppData(_data);
    if (_firebaseUid != null) {
      StorageService.instance.saveToFirestore(_firebaseUid!, _data);
    }
  }

  //<3<3<3<3<3<3<3<3<3<3<3 Semester settings <3<3<3<3<3<3<3<3<3<3<3<3

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

  //<3<3<3<3<3<3<3<3<3<3<3 Courses <3<3<3<3<3<3<3<3<3<3<3

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

  Future<void> clearCourseSchedule(String courseId) async {
    final updated =
        _data.schedule.where((s) => s.courseId != courseId).toList();
    _data = _data.copyWith(schedule: updated);
    await _save();
    notifyListeners();
  }

  //<3<3<3<3<3<3<3<3 Schedule entries <3<3<3<3<3<3<3<3

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

  Future<void> updateFutureWeekdaySessions(String courseId, int weekday,
      DateTime fromDate, String newStart, String newEnd) async {
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

  //<3<3<3<3<3<3<3<3 Calendar sync <3<3<3<3<3<3<3<3

  static double _parseDuration(String start, String end) {
    double toH(String t) {
      final p = t.split(':');
      if (p.length < 2) return 0;
      return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
    }
    return (toH(end) - toH(start)).clamp(0.0, 24.0);
  }

  double completedHoursForCourse(String courseId) {
    double total = 0;
    for (final e in _data.schedule) {
      if (e.courseId == courseId && e.completed) {
        total += _parseDuration(e.startTime, e.endTime);
      }
    }
    return total;
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

  //<3<3<3<3<3<3 Grade multipliers <3<3<3<3<3<3>
  double effectiveCompletedHours(Course course) {
    final fromSchedule = completedHoursForCourse(course.id);
    return course.catchUpMode
        ? fromSchedule + course.hoursStudiedSoFar
        : fromSchedule;
  }

  double targetHoursForGrade(Course course, String grade) {
    final m = gradeMultiplier(grade) ?? 0.0;
    if (m == 0) return 0;
    if (semesterCredits > 0 && semesterWeeks > 0 && course.credits > 0) {
      return (course.credits / semesterCredits) * 37.5 * semesterWeeks * m;
    }
    return course.credits * 25 * m; 
  }

  double remainingHours(Course course) {
    final target = targetHoursForGrade(course, course.targetGrade);
    final done = effectiveCompletedHours(course);
    return (target - done).clamp(0.0, double.infinity);
  }

  double? dynamicWeeklyHours(Course course) {
    final weeksLeft = weeksRemainingForCourse(course);
    if (weeksLeft == null || weeksLeft <= 0) return null;
    final rem = remainingHours(course);
    if (rem <= 0) return 0;
    return rem / weeksLeft;
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

  //<3<3<3<3<3<3<3<3<3<3<3<3 User management <3<3<3<3<3<3<3<3<3<3<3<3
  Future<void> saveUserEmail(String email) async {
    _userEmail = email;
    await StorageService.instance.saveUserEmail(email);
    notifyListeners();
  }

  Future<void> setFirebaseUser(String uid, String email) async {
    _firebaseUid = uid;
    _userEmail = email;
    await StorageService.instance.saveUserEmail(email);

    try {
      final cloudData = await StorageService.instance.loadFromFirestore(uid);
      if (cloudData != null) {
        _data = cloudData;
        await StorageService.instance.saveAppData(_data);
      } else {
        await StorageService.instance.saveToFirestore(uid, _data);
      }
    } catch (_) {
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
  Future<void> deleteFirestoreData() async {
    if (_firebaseUid == null) return;
    await StorageService.instance.deleteUserData(_firebaseUid!);
  }
  Future<void> clearLocalAfterDelete() async {
    await StorageService.instance.clearAll();
    _data = AppData();
    _userEmail = null;
    _firebaseUid = null;
    notifyListeners();
  }
  Future<void> deleteAccount() async {
    await deleteFirestoreData();
    await FirebaseAuth.instance.currentUser?.delete();
    await clearLocalAfterDelete();
  }
}

//<3<3<3<3<3<3<3<3<3 Provider <3<3<3<3<3<3<3<3<3

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
