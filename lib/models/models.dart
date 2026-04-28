import 'dart:convert';

// ─── GRADE MULTIPLIER ────────────────────────────────────────────────────────

double? gradeMultiplier(String grade) {
  switch (grade.toUpperCase()) {
    case 'A': return 0.9;
    case 'B': return 0.8;
    case 'C': return 0.6;
    case 'D': return 0.5;
    case 'E': return 0.4;
    case 'F': return 0.0;
    default:  return null;
  }
}

// ─── COURSE ──────────────────────────────────────────────────────────────────

class Course {
  final String id;
  final String name;
  final double credits;
  final String targetGrade;
  final double hoursPerDay;
  final int daysPerWeek;
  final bool hoursMode;           // true = hours-per-day mode
  final bool catchUpMode;         // true = catch-up recalculation mode
  final DateTime? examDate;
  final double hoursStudiedSoFar; // persisted catch-up input
  final int color;                // Color.value; 0 = auto-assign from presets

  Course({
    required this.id,
    required this.name,
    required this.credits,
    required this.targetGrade,
    required this.hoursPerDay,
    required this.daysPerWeek,
    this.hoursMode = false,
    this.catchUpMode = false,
    this.examDate,
    this.hoursStudiedSoFar = 0,
    this.color = 0,
  });

  Course copyWith({
    String? id,
    String? name,
    double? credits,
    String? targetGrade,
    double? hoursPerDay,
    int? daysPerWeek,
    bool? hoursMode,
    bool? catchUpMode,
    DateTime? examDate,
    bool clearExamDate = false,
    double? hoursStudiedSoFar,
    int? color,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      targetGrade: targetGrade ?? this.targetGrade,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      hoursMode: hoursMode ?? this.hoursMode,
      catchUpMode: catchUpMode ?? this.catchUpMode,
      examDate: clearExamDate ? null : examDate ?? this.examDate,
      hoursStudiedSoFar: hoursStudiedSoFar ?? this.hoursStudiedSoFar,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'credits': credits,
        'targetGrade': targetGrade,
        'hoursPerDay': hoursPerDay,
        'daysPerWeek': daysPerWeek,
        'hoursMode': hoursMode,
        'catchUpMode': catchUpMode,
        'examDate': examDate?.toIso8601String(),
        'hoursStudiedSoFar': hoursStudiedSoFar,
        'color': color,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        name: json['name'] as String,
        credits: (json['credits'] as num).toDouble(),
        targetGrade: json['targetGrade'] as String,
        hoursPerDay: (json['hoursPerDay'] as num).toDouble(),
        daysPerWeek: json['daysPerWeek'] as int,
        hoursMode: json['hoursMode'] as bool? ?? false,
        catchUpMode: json['catchUpMode'] as bool? ?? false,
        examDate: json['examDate'] != null
            ? DateTime.tryParse(json['examDate'] as String)
            : null,
        hoursStudiedSoFar:
            (json['hoursStudiedSoFar'] as num?)?.toDouble() ?? 0,
        color: json['color'] as int? ?? 0,
      );
}

// ─── SCHEDULE ENTRY ──────────────────────────────────────────────────────────

class ScheduleEntry {
  final String id;
  final String courseId;
  final String courseName;
  final DateTime date;
  final String startTime;
  final String endTime;
  bool completed;

  ScheduleEntry({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.completed = false,
  });

  ScheduleEntry copyWith({
    String? id,
    String? courseId,
    String? courseName,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? completed,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'courseName': courseName,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'completed': completed,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        courseName: json['courseName'] as String,
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        completed: json['completed'] as bool? ?? false,
      );
}

// ─── APP DATA ─────────────────────────────────────────────────────────────────

class AppData {
  final int semesterCredits;
  final int semesterWeeks;
  final DateTime? semesterStartDate;
  final List<Course> courses;
  final List<ScheduleEntry> schedule;

  AppData({
    this.semesterCredits = 30,
    this.semesterWeeks = 14,
    this.semesterStartDate,
    List<Course>? courses,
    List<ScheduleEntry>? schedule,
  })  : courses = courses ?? [],
        schedule = schedule ?? [];

  /// 1-based current week in the semester, or null if no start date set.
  int? get currentSemesterWeek {
    if (semesterStartDate == null) return null;
    final today = DateTime.now();
    final start = DateTime(semesterStartDate!.year,
        semesterStartDate!.month, semesterStartDate!.day);
    final diff = today.difference(start).inDays;
    if (diff < 0) return null; // semester hasn't started
    return (diff ~/ 7) + 1;
  }

  /// Weeks remaining (inclusive of current week), or null if no start date.
  int? get weeksRemaining {
    final cur = currentSemesterWeek;
    if (cur == null) return null;
    return (semesterWeeks - cur + 1).clamp(0, semesterWeeks);
  }

  AppData copyWith({
    int? semesterCredits,
    int? semesterWeeks,
    DateTime? semesterStartDate,
    bool clearStartDate = false,
    List<Course>? courses,
    List<ScheduleEntry>? schedule,
  }) {
    return AppData(
      semesterCredits: semesterCredits ?? this.semesterCredits,
      semesterWeeks: semesterWeeks ?? this.semesterWeeks,
      semesterStartDate: clearStartDate
          ? null
          : semesterStartDate ?? this.semesterStartDate,
      courses: courses ?? this.courses,
      schedule: schedule ?? this.schedule,
    );
  }

  Map<String, dynamic> toJson() => {
        'semesterCredits': semesterCredits,
        'semesterWeeks': semesterWeeks,
        'semesterStartDate': semesterStartDate?.toIso8601String(),
        'courses': courses.map((c) => c.toJson()).toList(),
        'schedule': schedule.map((s) => s.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        semesterCredits: json['semesterCredits'] as int? ?? 30,
        semesterWeeks: json['semesterWeeks'] as int? ?? 14,
        semesterStartDate: json['semesterStartDate'] != null
            ? DateTime.tryParse(json['semesterStartDate'] as String)
            : null,
        courses: (json['courses'] as List<dynamic>?)
                ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        schedule: (json['schedule'] as List<dynamic>?)
                ?.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String toJsonString() => jsonEncode(toJson());
  factory AppData.fromJsonString(String s) => AppData.fromJson(jsonDecode(s));

  double get totalCourseCredits =>
      courses.fold(0.0, (sum, c) => sum + c.credits);
}

// ─── COURSE COLOR PRESETS ─────────────────────────────────────────────────────

class CourseColors {
  static const List<int> presets = [
    0xFFD64545, // Crimson
    0xFFE76F51, // Coral
    0xFFE67E22, // Orange
    0xFF2ECC71, // Emerald
    0xFF5AA469, // Forest green
    0xFF43AA8B, // Sage
    0xFF2A9D8F, // Teal
    0xFF5B6EE1, // Indigo
    0xFF6A4C93, // Royal purple
    0xFF8E44AD, // Purple
    0xFFD16D9E, // Pink
    0xFFF72585, // Hot magenta
    0xFF9C6644, // Brown
    0xFF3A86FF, // Electric blue
  ];
}
