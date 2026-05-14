import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../models/models.dart';

import '../widgets/shared_widgets.dart';
import '../widgets/cards/course_card.dart';
import '../widgets/cards/total_credits_bar.dart';
import '../widgets/feedback/empty_state_view.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/buttons/time_picker_btn.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';
import 'calculate_screen.dart';

class _DayConfig {
  final int weekday; 
  TimeOfDay startTime;
  String label = '';
  _DayConfig({required this.weekday, required this.startTime});
}

class CoursesScreen extends StatelessWidget {
  final void Function(int) onNavTap;
  const CoursesScreen({super.key, required this.onNavTap});

  static double _parseHour(String t) {
    final p = t.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
  }

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
                        ? EmptyStateView(
                            icon: Icons.school_rounded,
                            iconColor:
                                AppColors.cardDark.withValues(alpha: 0.4),
                            title: 'No courses yet',
                            subtitle: 'Tap below to add your first course',
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.courses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) => CourseCard(
                              course: state.courses[i],
                              onSchedule: () => _autoScheduleCourse(
                                  context, state, state.courses[i]),
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CalculateScreen(course: state.courses[i]),
                                ),
                              ),
                              onDelete: () => _confirmDelete(
                                  context, state, state.courses[i]),
                              onClearSchedule: () => _confirmClearSchedule(
                                  context, state, state.courses[i]),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Total credits bar
                  if (state.courses.isNotEmpty) TotalCreditsBar(state: state),
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
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Course',
      message:
          'Remove "${course.name}"? All related sessions will also be deleted.',
      confirmLabel: 'Delete',
    );
    if (confirmed) state.deleteCourse(course.id);
  }

  Future<void> _confirmClearSchedule(
      BuildContext context, AppState state, Course course) async {
    final count = state.schedule.where((s) => s.courseId == course.id).length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sessions to clear for this course.')),
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear Schedule',
      message:
          'Remove all $count session${count == 1 ? '' : 's'} for "${course.name}"?',
      confirmLabel: 'Clear',
    );
    if (confirmed) state.clearCourseSchedule(course.id);
  }

  Future<List<_DayConfig>?> _showAutoScheduleConfig(
      BuildContext context, Course course) async {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const labelOptions = ['', 'Lecture', 'Exercise', 'Self-study'];
    const labelDisplay = ['—', 'Lecture', 'Exercise', 'Self-study'];

    final defaultCount = course.daysPerWeek.clamp(1, 5);
    final configMap = <int, _DayConfig>{};
    for (int i = 0; i < defaultCount; i++) {
      configMap[i + 1] = _DayConfig(
          weekday: i + 1, startTime: const TimeOfDay(hour: 9, minute: 0));
    }
    final selected = <int>{...configMap.keys};

    return showDialog<List<_DayConfig>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final sortedDays = selected.toList()..sort();
          return AlertDialog(
            backgroundColor: AppColors.bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Schedule Settings',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: Ts.s(ctx, 20))),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //<3<3<3<3<3<3<3<3 Study days <3<3<3<3<3<3<3<3
                    Text('Study days',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: Ts.s(ctx, 15))),
                    const SizedBox(height: 8),
                    LayoutBuilder(builder: (_, box) {
                      const gap = 5.0;
                      final btnW = (box.maxWidth - gap * 6) / 7;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final on = selected.contains(day);
                          return GestureDetector(
                            onTap: () => set(() {
                              if (on) {
                                selected.remove(day);
                                configMap.remove(day);
                              } else {
                                selected.add(day);
                                configMap[day] = _DayConfig(
                                    weekday: day,
                                    startTime:
                                        const TimeOfDay(hour: 9, minute: 0));
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
                                  color: on
                                      ? AppColors.cardDark
                                      : Colors.white.withValues(alpha: 0.18),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(dayNames[i][0],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize:
                                            (btnW * 0.4).clamp(9.0, 14.0))),
                              ),
                            ),
                          );
                        }),
                      );
                    }),

                    if (sortedDays.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...sortedDays.map((wd) {
                        final cfg = configMap[wd]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dayNames[wd - 1],
                                  style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: Ts.s(ctx, 14))),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final t = await pickTime(
                                          context, cfg.startTime);
                                      if (t != null) {
                                        set(() => cfg.startTime = t);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                            width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time_rounded,
                                              color: Colors.white70, size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${cfg.startTime.hour.toString().padLeft(2, '0')}:'
                                            '${cfg.startTime.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: Ts.s(ctx, 14)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 5,
                                      runSpacing: 4,
                                      children: List.generate(
                                          labelOptions.length, (i) {
                                        final sel =
                                            cfg.label == labelOptions[i];
                                        return GestureDetector(
                                          onTap: () => set(() =>
                                              cfg.label = labelOptions[i]),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: sel
                                                  ? AppColors.cardDark
                                                  : AppColors.card,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: sel
                                                    ? AppColors.cardDark
                                                    : Colors.white.withValues(
                                                        alpha: 0.18),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              labelDisplay[i],
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: sel
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  fontSize: Ts.s(ctx, 12)),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
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
                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Select at least one day.')));
                    return;
                  }
                  Navigator.pop(
                      ctx, sortedDays.map((wd) => configMap[wd]!).toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Generate',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
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

  Future<bool?> _showAutoScheduleConfirm(
      BuildContext context,
      List<ScheduleEntry> entries,
      DateTime firstDate,
      List<_DayConfig> dayConfigs) {
    final Map<String, int> countByCourse = {};
    for (final e in entries) {
      countByCourse[e.courseName] = (countByCourse[e.courseName] ?? 0) + 1;
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Suggested Schedule',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(ctx, 20))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starting ${DateFormat('d MMM').format(firstDate)} · ${entries.length} sessions',
              style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontSize: Ts.s(ctx, 14),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...countByCourse.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                        child: Text(e.key,
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: Ts.s(ctx, 15)))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${e.value} sessions',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: Ts.s(ctx, 13))),
                    ),
                  ]),
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: dayConfigs.map((d) {
                final name = dayNames[d.weekday - 1];
                final t = '${d.startTime.hour.toString().padLeft(2, '0')}:'
                    '${d.startTime.minute.toString().padLeft(2, '0')}';
                final lbl = d.label.isNotEmpty ? ' · ${d.label}' : '';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardDark, width: 1),
                  ),
                  child: Text('$name $t$lbl',
                      style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: Ts.s(ctx, 13))),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  //<3<3<3<3<3<3<3<3 auto-schedule course <3<3<3<33<3<3<3<3<3<3

  Future<void> _autoScheduleCourse(
      BuildContext context, AppState state, Course course) async {
    final dayConfigs = await _showAutoScheduleConfig(context, course);
    if (dayConfigs == null || dayConfigs.isEmpty) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final semStart = state.semesterStartDate;
    final effectiveStart = (semStart != null && semStart.isAfter(todayOnly))
        ? DateTime(semStart.year, semStart.month, semStart.day)
        : todayOnly;

    final startMonday =
        effectiveStart.subtract(Duration(days: effectiveStart.weekday - 1));

    final Map<String, double> dateMaxEnd = {};
    for (final entry in state.schedule) {
      if (entry.courseId == course.id) continue;
      if (entry.date.isBefore(todayOnly)) continue;
      final endH = _parseHour(entry.endTime);
      final dateKey =
          DateTime(entry.date.year, entry.date.month, entry.date.day)
              .toIso8601String();
      if (endH > (dateMaxEnd[dateKey] ?? 0)) dateMaxEnd[dateKey] = endH;
    }

    final DateTime endDate;
    if (course.examDate != null) {
      endDate = DateTime(
          course.examDate!.year, course.examDate!.month, course.examDate!.day);
    } else if (state.semesterStartDate != null && state.semesterWeeks > 0) {
      endDate =
          state.semesterStartDate!.add(Duration(days: state.semesterWeeks * 7));
    } else {
      endDate = startMonday.add(const Duration(days: 98));
    }

    final totalDays = endDate.difference(startMonday).inDays;
    if (totalDays <= 0 || course.hoursPerDay <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Cannot schedule: check exam date and course hours.')));
      }
      return;
    }
    final weeks = (totalDays / 7).ceil();

    final weeklyHours = course.hoursPerDay * course.daysPerWeek;
    final hPerSession = weeklyHours / dayConfigs.length;
    final configMap = {for (final d in dayConfigs) d.weekday: d};
    final selectedDays = dayConfigs.map((d) => d.weekday).toList()..sort();

    final entries = <ScheduleEntry>[];
    for (int w = 0; w < weeks; w++) {
      for (final wd in selectedDays) {
        final date = startMonday.add(Duration(days: w * 7 + (wd - 1)));
        if (date.isAfter(endDate) || date.isBefore(effectiveStart)) continue;
        final dateKey =
            DateTime(date.year, date.month, date.day).toIso8601String();
        final cfg = configMap[wd]!;
        final cfgStartH = cfg.startTime.hour + cfg.startTime.minute / 60.0;
        final existingEnd = dateMaxEnd[dateKey];
        final sH = (existingEnd != null && existingEnd > cfgStartH)
            ? existingEnd
            : cfgStartH;
        final eH = sH + hPerSession;
        entries.add(ScheduleEntry(
          id: '${course.id}_auto_${date.toIso8601String()}',
          courseId: course.id,
          courseName: course.name,
          date: date,
          startTime: _fmtHour(sH),
          endTime: _fmtHour(eH),
          label: cfg.label,
        ));
      }
    }

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No sessions generated. Check exam date.')));
      }
      return;
    }

    if (!context.mounted) return;
    final firstDate =
        entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final confirmed =
        await _showAutoScheduleConfirm(context, entries, firstDate, dayConfigs);

    if (confirmed == true && context.mounted) {
      await state.removeAutoScheduleForCourses([course.id]);
      await state.addScheduleEntries(entries);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Added ${entries.length} sessions for ${course.name}.')));
      }
    }
  }
}
