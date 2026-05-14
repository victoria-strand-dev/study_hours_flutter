import 'dart:convert';

///<3<3<3<3<3<3<3<3 Grade Multiplier <3<3<3<3<3<3<3<3

double? gradeMultiplier(String grade) {
  switch (grade.toUpperCase()) {
    case 'A':
      return 0.9;
    case 'B':
      return 0.8;
    case 'C':
      return 0.6;
    case 'D':
      return 0.5;
    case 'E':
      return 0.4;
    case 'F':
      return 0.0;
    default:
      return null;
  }
}

///<3<3<3<3<3<3<3<3 Course <3<3<3<3<3<3<3<3

class Course {
  final String id;
  final String name;
  final double credits;
  final String targetGrade;
  final double hoursPerDay;
  final int daysPerWeek;
  final bool hoursMode;
  final bool catchUpMode;
  final DateTime? examDate;
  final double hoursStudiedSoFar;
  final int color;

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

  ///<3<3<3<3<3<3<3<3 JSON <3<3<3<3<3<3<3<3

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
        hoursStudiedSoFar: (json['hoursStudiedSoFar'] as num?)?.toDouble() ?? 0,
        color: json['color'] as int? ?? 0,
      );

  ///<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
}

///<3<3<3<3<3<3<3<3 Schedule Entry <3<3<3<3<3<3<3<3

class ScheduleEntry {
  final String id;
  final String courseId;
  final String courseName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String label;
  bool completed;

  ScheduleEntry({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.label = '',
    this.completed = false,
  });

  ScheduleEntry copyWith({
    String? id,
    String? courseId,
    String? courseName,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? label,
    bool? completed,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      completed: completed ?? this.completed,
    );
  }

  ///<3<3<3<3<3<3<3<3 JSON <3<3<3<3<3<3<3<3

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'courseName': courseName,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'label': label,
        'completed': completed,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        courseName: json['courseName'] as String,
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        label: json['label'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );

  ///<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
}

///<3<3<3<3<3<3<3<3 App Data <3<3<3<3<3<3<3<3

class AppData {
  final int semesterCredits;
  final int semesterWeeks;
  final DateTime? semesterStartDate;
  final List<Course> courses;
  final List<ScheduleEntry> schedule;

  AppData({
    this.semesterCredits = 30,
    this.semesterWeeks = 19,
    this.semesterStartDate,
    List<Course>? courses,
    List<ScheduleEntry>? schedule,
  })  : courses = courses ?? [],
        schedule = schedule ?? [];

  ///<3<3<3<3<3<3<3<3 Getters <3<3<3<3<3<3<3<3

  int? get currentSemesterWeek {
    if (semesterStartDate == null) return null;
    final today = DateTime.now();
    final start = DateTime(semesterStartDate!.year, semesterStartDate!.month,
        semesterStartDate!.day);
    final diff = today.difference(start).inDays;
    if (diff < 0) return null;
    return (diff ~/ 7) + 1;
  }

  int? get weeksRemaining {
    final cur = currentSemesterWeek;
    if (cur == null) return null;
    return (semesterWeeks - cur + 1).clamp(0, semesterWeeks);
  }

  double get totalCourseCredits =>
      courses.fold(0.0, (sum, c) => sum + c.credits);

  ///<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3

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
      semesterStartDate:
          clearStartDate ? null : semesterStartDate ?? this.semesterStartDate,
      courses: courses ?? this.courses,
      schedule: schedule ?? this.schedule,
    );
  }

  ///<3<3<3<3<3<3<3<3 JSON <3<3<3<3<3<3<3<3

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

  ///<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
}

///<3<3<3<3<3<3<3<3 Course Colors <3<3<3<3<3<3<3<3

class CourseColors {
  static const List<int> presets = [
    0xFFD64545,
    0xFFE76F51,
    0xFFE67E22,
    0xFF429E69,
    0xFF5AA469,
    0xFF43AA8B,
    0xFF2A9D8F,
    0xFF5B6EE1,
    0xFF6A4C93,
    0xFF8E44AD,
    0xFFD16D9E,
    0xFFF72585,
    0xFF9C6644,
    0xFF3A86FF,
  ];
}
