import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'calculate_screen.dart';
import '../theme/app_text.dart'; // Ts

Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    initialEntryMode: TimePickerEntryMode.dial,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              entryModeIconColor: Color(0x00000000),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurface,
              ),
            ),
          ),
          child: child!,
        ),
      );
    },
  );
}

class CoursesScreen extends StatelessWidget {
  final void Function(int) onNavTap;
  const CoursesScreen({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final size = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.05).clamp(14.0, 40.0);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          buildAppBar(
            context,
            'COURSES',
            showBack: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsIconButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                ProfileIconButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  Expanded(
                    child: state.courses.isEmpty
                        ? _EmptyCourses(
                            onAdd: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalculateScreen(),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.courses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) => _CourseCard(
                              course: state.courses[i],
                              onSchedule: () => _autoScheduleCourse(
                                  context, state, state.courses[i]),
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CalculateScreen(
                                      course: state.courses[i]),
                                ),
                              ),
                              onDelete: () =>
                                  _confirmDelete(context, state, state.courses[i]),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Total credits bar
                  if (state.courses.isNotEmpty)
                    _TotalCreditsBar(state: state),
                  const SizedBox(height: 8),
                  // Add course button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalculateScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Course',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${course.name}"? All related sessions will also be deleted.',
          style: const TextStyle(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) state.deleteCourse(course.id);
  }

  // ─── Auto-schedule ───────────────────────────────────────────────────────────

  /// Picks up to [n] allowed weekdays with the least accumulated load.
  /// A "fresh" day (nextStart == startH, nothing stacked yet) is always allowed.
  /// A day that already has a stacked course is only allowed if adding
  /// [sessionHours] would not push past midnight.
  Set<int> _pickLeastLoadedDays(
      Map<int, double> load, int n, Set<int> allowed,
      Map<int, double> nextStart, double startH, double sessionHours) {
    final valid = load.entries.where((e) {
      if (!allowed.contains(e.key)) return false;
      final ns = nextStart[e.key] ?? startH;
      // Fresh day → always allow (user's chosen start time, their responsibility)
      // Stacked day → only allow if it won't overflow midnight
      return ns <= startH || ns + sessionHours <= 24.0;
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return valid.take(n.clamp(0, valid.length)).map((e) => e.key).toSet();
  }

  /// Shows the "Suggest Schedule" config dialog.
  /// Returns (startTime, allowedWeekdays) or null if cancelled.
  Future<(TimeOfDay, Set<int>)?> _showAutoScheduleConfig(
      BuildContext context) async {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    // Default: Mon–Fri only
    Set<int> allowed = {1, 2, 3, 4, 5};
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return showDialog<(TimeOfDay, Set<int>)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          return AlertDialog(
            backgroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Schedule Settings',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(ctx, 20),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Start time ──
                Text('Start time',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: Ts.s(ctx, 15),
                    )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final t = await _pickTime(context, startTime);
                    if (t != null) set(() => startTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${startTime.hour.toString().padLeft(2, '0')}:'
                          '${startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: Ts.s(ctx, 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Weekday toggles ──
                Text('Study days',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: Ts.s(ctx, 15),
                    )),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (_, box) {
                  const gap = 5.0;
                  final btnW = (box.maxWidth - gap * 6) / 7;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final on = allowed.contains(day);
                      return GestureDetector(
                        onTap: () => set(() {
                          if (on) {
                            allowed.remove(day);
                          } else {
                            allowed.add(day);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: btnW,
                          height: btnW,
                          decoration: BoxDecoration(
                            color: on ? AppColors.cardDark : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: on ? AppColors.cardDark : Colors.white.withValues(alpha: 0.18),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              dayLabels[i],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: (btnW * 0.4).clamp(9.0, 14.0),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (allowed.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Select at least one day.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, (startTime, allowed));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Generate',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtHour(double hour) {
    final h = hour.floor().clamp(0, 23);
    final m = ((hour - hour.floor()) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showAutoScheduleConfirm(BuildContext context,
      List<ScheduleEntry> entries, DateTime firstDate, TimeOfDay startTime,
      List<String> redistributed) {
    final Map<String, int> countByCourse = {};
    for (final e in entries) {
      countByCourse[e.courseName] = (countByCourse[e.courseName] ?? 0) + 1;
    }
    final startHH = startTime.hour.toString().padLeft(2, '0');
    final startMM = startTime.minute.toString().padLeft(2, '0');

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Suggested Schedule',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: Ts.s(ctx, 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Starting ${DateFormat('d MMM').format(firstDate)} · ${entries.length} sessions',
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontSize: Ts.s(ctx, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...countByCourse.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: Ts.s(ctx, 15),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${e.value} sessions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: Ts.s(ctx, 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Text(
                'Starting at $startHH:$startMM. Courses on shared days are stacked back-to-back.',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: Ts.s(ctx, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (redistributed.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardDark, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.textDark, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${redistributed.join(', ')}: fewer days available than set — session length adjusted to keep weekly hours on target.',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: Ts.s(ctx, 13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add to Calendar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ─── Per-course smart scheduling ─────────────────────────────────────────────

  /// Parses "HH:MM" to fractional hours.
  double _parseHourStr(String time) {
    final p = time.split(':');
    if (p.length != 2) return 0;
    return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
  }

  /// Smart per-course suggest: picks days around existing calendar entries.
  Future<void> _autoScheduleCourse(
      BuildContext context, AppState state, Course course) async {
    final config = await _showAutoScheduleConfig(context);
    if (config == null) return;

    final TimeOfDay startTime = config.$1;
    final Set<int> allowedDays = config.$2;
    final double startH = startTime.hour + startTime.minute / 60.0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Don't schedule before the semester start date if it's in the future.
    final semStart = state.semesterStartDate;
    final effectiveStart = (semStart != null && semStart.isAfter(todayOnly))
        ? DateTime(semStart.year, semStart.month, semStart.day)
        : todayOnly;

    final startMonday =
        effectiveStart.subtract(Duration(days: effectiveStart.weekday - 1));

    // Build per-weekday load for day-selection (average hours/weekday across future sessions).
    // Only used to pick the LEAST-loaded weekdays — NOT for start time calculation.
    final Map<int, double> dayLoad = {for (int d = 1; d <= 7; d++) d: 0.0};
    // Per-specific-date max end time from other courses — used for correct stacking.
    final Map<String, double> dateMaxEnd = {};

    for (final entry in state.schedule) {
      if (entry.courseId == course.id) continue;
      if (entry.date.isBefore(todayOnly)) continue;
      final wd = entry.date.weekday;
      final endH = _parseHourStr(entry.endTime);
      final dur = endH - _parseHourStr(entry.startTime);
      if (dur > 0) dayLoad[wd] = (dayLoad[wd] ?? 0) + dur;
      // Track max end time per exact calendar date for stacking
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day)
          .toIso8601String();
      if (endH > (dateMaxEnd[dateKey] ?? startH)) dateMaxEnd[dateKey] = endH;
    }

    // For _pickLeastLoadedDays we still need per-weekday "typical" next start.
    // Use startH (user's chosen time) as default — stacking is now per-date below.
    final Map<int, double> dayNextStart = {for (int d = 1; d <= 7; d++) d: startH};

    // End date
    final DateTime endDate;
    if (course.examDate != null) {
      endDate = DateTime(
          course.examDate!.year, course.examDate!.month, course.examDate!.day);
    } else if (state.semesterStartDate != null && state.semesterWeeks > 0) {
      endDate = state.semesterStartDate!
          .add(Duration(days: state.semesterWeeks * 7));
    } else {
      endDate = startMonday.add(const Duration(days: 98));
    }

    final totalDays = endDate.difference(startMonday).inDays;
    if (totalDays <= 0 || course.hoursPerDay <= 0 || course.daysPerWeek <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cannot schedule: check exam date and course hours.')));
      }
      return;
    }
    final weeks = (totalDays / 7).ceil();

    final weeklyHours = course.hoursPerDay * course.daysPerWeek;
    final wantDays = course.daysPerWeek.clamp(1, allowedDays.length);

    var days = _pickLeastLoadedDays(
        dayLoad, wantDays, allowedDays, dayNextStart, startH, course.hoursPerDay);

    bool redistributed = false;
    double hPerSession = course.hoursPerDay;
    if (days.isNotEmpty && days.length < course.daysPerWeek) {
      redistributed = true;
      hPerSession = weeklyHours / days.length;
      final rechosen = _pickLeastLoadedDays(
          dayLoad, days.length, allowedDays, dayNextStart, startH, hPerSession);
      if (rechosen.isNotEmpty) days = rechosen;
      hPerSession = weeklyHours / days.length;
    }

    if (days.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No available days. Try a different start time or more days.')));
      }
      return;
    }

    // Generate entries with CORRECT per-date start times.
    // Each session starts at max(startH, latestEndTimeOnThatDate) so courses
    // stack back-to-back on the same actual day, not on a global weekday average.
    final entries = <ScheduleEntry>[];
    for (int w = 0; w < weeks; w++) {
      for (final wd in days) {
        final date = startMonday.add(Duration(days: w * 7 + (wd - 1)));
        if (date.isAfter(endDate) || date.isBefore(effectiveStart)) continue;
        final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();
        final sH = dateMaxEnd[dateKey] ?? startH;
        final eH = sH + hPerSession;
        final sStr = _fmtHour(sH);
        final eStr = _fmtHour(eH);
        entries.add(ScheduleEntry(
          id: '${course.id}_auto_${date.toIso8601String()}',
          courseId: course.id,
          courseName: course.name,
          date: date,
          startTime: sStr,
          endTime: eStr,
        ));
      }
    }

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sessions generated. Check exam date.')));
      }
      return;
    }

    if (!context.mounted) return;
    final firstDate =
        entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final confirmed = await _showAutoScheduleConfirm(
        context, entries, firstDate, startTime,
        redistributed ? [course.name] : []);

    if (confirmed == true && context.mounted) {
      await state.removeAutoScheduleForCourses([course.id]);
      await state.addScheduleEntries(entries);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Added ${entries.length} sessions for ${course.name}.')));
      }
    }
  }

}

Color gradeColor(String g) => AppColors.gradeColor(g);

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onSchedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final courseColor = state.courseColorOf(course.id);
    final creditsStr = course.credits % 1 == 0
        ? course.credits.toInt().toString()
        : course.credits.toString();
    final daysLabel = course.daysPerWeek == 1
        ? '1 day'
        : '${course.daysPerWeek} days';

    final completed = state.effectiveCompletedHours(course);
    final required  = state.requiredHoursForCourse(course);
    final hasProgress = required != null && required > 0;
    final progress = hasProgress
        ? (completed / required).clamp(0.0, 1.0)
        : 0.0;
    final done = hasProgress && progress >= 1.0;

    // Dynamic weekly hours (recalculated from actual progress + time left)
    final dynWeekly  = state.dynamicWeeklyHours(course);
    final weeksLeft  = state.weeksRemainingForCourse(course);
    final String resultText;
    if (done) {
      resultText = 'Goal reached for ${course.targetGrade}!';
    } else if (dynWeekly != null && dynWeekly <= 0) {
      resultText = 'Hours target reached for ${course.targetGrade}';
    } else if (dynWeekly != null && weeksLeft != null && weeksLeft > 0) {
      resultText = '${dynWeekly.toStringAsFixed(1)}h/week needed '
          '(${weeksLeft}w left) → ${course.targetGrade}';
    } else if (course.hoursPerDay <= 0 && course.hoursMode) {
      resultText = 'Hours target reached for ${course.targetGrade}';
    } else if (course.hoursMode) {
      resultText = 'Need ${course.hoursPerDay.toStringAsFixed(1)}h, '
          '$daysLabel/week → ${course.targetGrade}';
    } else {
      resultText = '${course.hoursPerDay.toStringAsFixed(1)}h, '
          '$daysLabel/week → Expected ${course.targetGrade}';
    }

    // Grade upgrade check
    final upgradeGrade = state.achievableUpgradeGrade(course);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? courseColor : Colors.white.withValues(alpha: 0.18), width: done ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardDark.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Decorative colour strip (colour set in Add/Edit course form)
            Container(width: 10, color: courseColor),
            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${course.name} | $creditsStr credits',
                          style: AppText.cardTitleLight,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          resultText,
                          style: AppText.bodyLight.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        if (course.examDate != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Exam: ${DateFormat('d MMM yyyy').format(course.examDate!)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: Ts.s(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (hasProgress) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.22),
                              valueColor: AlwaysStoppedAnimation<Color>(courseColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            done
                                ? 'Goal reached! ${completed.toStringAsFixed(1)}h completed'
                                : '${completed.toStringAsFixed(1)}h / ${required.toStringAsFixed(1)}h completed',
                            style: TextStyle(
                              color: done
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: done ? Ts.s(context, 15) : Ts.s(context, 14),
                              fontWeight: done ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                        if (upgradeGrade != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'At this pace you\'re on track for a $upgradeGrade',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: Ts.s(context, 13),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSchedule,
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white70, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded,
                        color: Colors.white70, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.white70, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _TotalCreditsBar extends StatelessWidget {
  final AppState state;
  const _TotalCreditsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.totalCourseCredits;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardDark,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total credits: ',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              total % 1 == 0 ? total.toInt().toString() : total.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(context, 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCourses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded,
              size: (size.width * 0.18).clamp(56.0, 80.0),
              color: AppColors.cardDark.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No courses yet',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: Ts.s(context, 19),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap below to add your first course',
            style: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.6),
              fontSize: Ts.s(context, 15),
            ),
          ),
        ],
      ),
    );
  }
}

