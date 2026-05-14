import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';

import '../widgets/calendar/day_picker_strip.dart';
import '../widgets/cards/next_session_hero_card.dart';
import '../widgets/cards/stat_mini_card.dart';
import '../widgets/calendar/semester_bar.dart';
import '../widgets/calendar/exam_row.dart';
import '../widgets/cards/course_progress_card.dart';
import '../widgets/feedback/empty_state_view.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  const HomeScreen({super.key, required this.onNavTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();

  static double _parseDuration(String start, String end) {
    double toH(String t) {
      final p = t.split(':');
      if (p.length < 2) return 0;
      return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
    }
    return (toH(end) - toH(start)).clamp(0.0, 24.0);
  }

  double _hoursThisWeek(AppState state) {
    final now = DateTime.now();
    final mon = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    return state.schedule
        .where(
            (e) => e.completed && !e.date.isBefore(mon) && !e.date.isAfter(sun))
        .fold(0.0, (s, e) => s + _parseDuration(e.startTime, e.endTime));
  }

  double _weeklyTarget(AppState state) =>
      state.courses.fold(0.0, (s, c) => s + c.hoursPerDay * c.daysPerWeek);

  int? _daysToExam(Course c) {
    if (c.examDate == null) return null;
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final examD =
        DateTime(c.examDate!.year, c.examDate!.month, c.examDate!.day);
    return examD.difference(todayD).inDays;
  }

  double _courseProgress(AppState state, Course c) {
    final completed = state.effectiveCompletedHours(c);
    final required = state.requiredHoursForCourse(c);
    if (required != null && required > 0) {
      return (completed / required).clamp(0.0, 1.0);
    }
    final multiplier = gradeMultiplier(c.targetGrade) ?? 0.8;
    final target = c.credits * 25 * multiplier;
    return target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
  }

  double _courseCompletedHours(AppState state, Course c) =>
      state.effectiveCompletedHours(c);

  ScheduleEntry? _nextEntry(AppState state) =>
      state.entriesForDay(_selectedDay).where((e) => !e.completed).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final today = DateTime.now();

    //<3<3<33<3<3<3<3<3<3 Greeting & date <3<3<3<3<3<3<3<3<3>
    final email = state.userEmail ?? '';
    final rawName = email.contains('@') ? email.split('@').first : 'Student';
    final name = rawName.length > 14 ? rawName.substring(0, 14) : rawName;

    final selectedEntries = state.entriesForDay(_selectedDay);
    final nextEntry = _nextEntry(state);
    final allDone = selectedEntries.isNotEmpty && nextEntry == null;

    final studied = _hoursThisWeek(state);
    final target = _weeklyTarget(state);
    final todayAll = state.entriesForDay(today);
    final todayDone = todayAll.where((e) => e.completed).length;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                Sp.s(context, 20), 16, Sp.s(context, 16), 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $name 👋',
                        style: GoogleFonts.nunito(
                          fontSize: Ts.s(context, 24),
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM').format(today),
                        style: GoogleFonts.nunito(
                          fontSize: Ts.s(context, 14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsIconButton(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                const SizedBox(width: 6),
                ProfileIconButton(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  Sp.s(context, 16), 0, Sp.s(context, 16), 100),
              physics: const BouncingScrollPhysics(),
              children: [
                DayPickerStrip(
                  selectedDay: _selectedDay,
                  onDaySelected: (d) => setState(() => _selectedDay = d),
                  state: state,
                ),

                const SizedBox(height: 16),

                NextSessionHeroCard(
                  entry: nextEntry,
                  onComplete: nextEntry != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          state.toggleEntryComplete(nextEntry.id);
                        }
                      : null,
                  allDone: allDone,
                  isEmpty: selectedEntries.isEmpty,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: StatMiniCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF6B35),
                        value: '${state.studyStreak}',
                        label: 'day streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatMiniCard(
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.card,
                        value: target > 0
                            ? '${studied.toStringAsFixed(1)}/${target.toStringAsFixed(0)}h'
                            : '${studied.toStringAsFixed(1)}h',
                        label: 'this week',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatMiniCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color.fromARGB(172, 0, 173, 72),
                        value: '$todayDone/${todayAll.length}',
                        label: 'done today',
                      ),
                    ),
                  ],
                ),

                if (state.semesterStartDate != null) ...[
                  const SizedBox(height: 16),
                  SemesterBar(state: state),
                ],

                if (state.courses.any((c) => c.examDate != null)) ...[
                  const SizedBox(height: 16),
                  ExamRow(state: state),
                ],

                //<3<3<3<3<3<3<3<3<3<3<3 Course progress <3<3<3<3<3<3<3<3<3<3<3
                if (state.courses.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'My Courses'),
                  const SizedBox(height: 10),
                  ...state.courses.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CourseProgressCard(
                          course: c,
                          progress: _courseProgress(state, c),
                          completedHours: _courseCompletedHours(state, c),
                          daysToExam: _daysToExam(c),
                          courseColor: state.courseColorOf(c.id),
                          onTap: () => widget.onNavTap(2),
                        ),
                      )),
                ],

                //<3<3<3<3<3<3<3<3<3<3 empty state for no courses <3<3<3<3<3<3<3<3<3>
                if (state.courses.isEmpty) ...[
                  const SizedBox(height: 24),
                  EmptyStateView(
                    icon: Icons.menu_book_rounded,
                    title: 'No courses yet',
                    subtitle: 'Add your first course to get started',
                    buttonLabel: 'Add Course',
                    onButtonTap: () => widget.onNavTap(2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
