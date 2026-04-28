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

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  const HomeScreen({super.key, required this.onNavTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();

  // ── Time helpers ────────────────────────────────────────────────────────
  static double _parseHour(String t) {
    final p = t.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p[1]) ?? 0) / 60.0;
  }

  static double _duration(String start, String end) =>
      (_parseHour(end) - _parseHour(start)).clamp(0.0, 24.0);

  // ── Stats ────────────────────────────────────────────────────────────────
  double _hoursThisWeek(AppState state) {
    final now  = DateTime.now();
    final mon  = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sun  = mon.add(const Duration(days: 6));
    return state.schedule
        .where((e) => e.completed && !e.date.isBefore(mon) && !e.date.isAfter(sun))
        .fold(0.0, (s, e) => s + _duration(e.startTime, e.endTime));
  }

  double _weeklyTarget(AppState state) =>
      state.courses.fold(0.0, (s, c) => s + c.hoursPerDay * c.daysPerWeek);

  // ── Exam urgency ─────────────────────────────────────────────────────────
  int? _daysToExam(Course c) {
    if (c.examDate == null) return null;
    final today   = DateTime.now();
    final todayD  = DateTime(today.year, today.month, today.day);
    final examD   = DateTime(c.examDate!.year, c.examDate!.month, c.examDate!.day);
    return examD.difference(todayD).inDays;
  }

  // ── Course progress (hours completed / target) ───────────────────────────
  double _courseProgress(AppState state, Course c) {
    final completed = state.schedule
        .where((e) => e.courseId == c.id && e.completed)
        .fold(0.0, (s, e) => s + _duration(e.startTime, e.endTime));
    final multiplier = gradeMultiplier(c.targetGrade) ?? 0.8;
    final target     = c.credits * 25 * multiplier;
    return target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
  }

  double _courseCompletedHours(AppState state, Course c) => state.schedule
      .where((e) => e.courseId == c.id && e.completed)
      .fold(0.0, (s, e) => s + _duration(e.startTime, e.endTime));

  // ── Next incomplete session for selected day ─────────────────────────────
  ScheduleEntry? _nextEntry(AppState state) =>
      state.entriesForDay(_selectedDay).where((e) => !e.completed).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final state   = AppStateProvider.of(context);
    final today   = DateTime.now();

    // Display name from email
    final email    = state.userEmail ?? '';
    final rawName  = email.contains('@') ? email.split('@').first : 'Student';
    final name     = rawName.length > 14 ? rawName.substring(0, 14) : rawName;

    final selectedEntries = state.entriesForDay(_selectedDay);
    final nextEntry       = _nextEntry(state);
    final allDone         = selectedEntries.isNotEmpty && nextEntry == null;

    final studied   = _hoursThisWeek(state);
    final target    = _weeklyTarget(state);
    final todayAll  = state.entriesForDay(today);
    final todayDone = todayAll.where((e) => e.completed).length;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.s(context, 20), 16, Sp.s(context, 16), 0),
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
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
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

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(Sp.s(context, 16), 0, Sp.s(context, 16), 100),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Day picker ────────────────────────────────────────────
                _DayPickerStrip(
                  selectedDay: _selectedDay,
                  onDaySelected: (d) => setState(() => _selectedDay = d),
                  state: state,
                ),

                const SizedBox(height: 16),

                // ── Next session hero card ─────────────────────────────────
                _NextSessionHeroCard(
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

                // ── Stats row (3 mini cards) ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatMiniCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF6B35),
                        value: '${state.studyStreak}',
                        label: 'day streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMiniCard(
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.cardDark,
                        value: target > 0
                            ? '${studied.toStringAsFixed(1)}/${target.toStringAsFixed(0)}h'
                            : '${studied.toStringAsFixed(1)}h',
                        label: 'this week',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMiniCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                        value: '$todayDone/${todayAll.length}',
                        label: 'done today',
                      ),
                    ),
                  ],
                ),

                // ── Semester progress (compact) ────────────────────────────
                if (state.semesterStartDate != null) ...[
                  const SizedBox(height: 16),
                  _SemesterBar(state: state),
                ],

                // ── Exam countdowns ────────────────────────────────────────
                if (state.courses.any((c) => c.examDate != null)) ...[
                  const SizedBox(height: 16),
                  _ExamRow(state: state),
                ],

                // ── Courses ───────────────────────────────────────────────
                if (state.courses.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'My Courses'),
                  const SizedBox(height: 10),
                  ...state.courses.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseProgressCard(
                          course: c,
                          progress: _courseProgress(state, c),
                          completedHours: _courseCompletedHours(state, c),
                          daysToExam: _daysToExam(c),
                          courseColor: state.courseColorOf(c.id),
                          onTap: () => widget.onNavTap(2),
                        ),
                      )),
                ],

                // ── Empty state ───────────────────────────────────────────
                if (state.courses.isEmpty) ...[
                  const SizedBox(height: 24),
                  _EmptyHome(onNavTap: widget.onNavTap),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DAY PICKER STRIP ─────────────────────────────────────────────────────────
// Fixed 7-day strip: Mon–Sun of the current week.
// Selected day = white card (Von Restorff pop on blue bg).
// Orange dot = has sessions. No past-week confusion — use Calendar tab for history.

class _DayPickerStrip extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final AppState state;

  const _DayPickerStrip({
    required this.selectedDay,
    required this.onDaySelected,
    required this.state,
  });

  static DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final monday = _monday(today);
    final days   = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Row(
      children: days.map((day) {
        final isToday    = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final isSelected = day.year == selectedDay.year &&
            day.month == selectedDay.month &&
            day.day == selectedDay.day;
        final hasEntries = state.entriesForDay(day).isNotEmpty;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDaySelected(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surface
                    : isToday
                        ? AppColors.cardDark.withValues(alpha: 0.35)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.cardDark.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 1).toUpperCase() +
                        DateFormat('E').format(day).substring(1, 2),
                    style: GoogleFonts.nunito(
                      color: isSelected
                          ? AppColors.onSurfaceMid
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: Ts.s(context, 13),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.nunito(
                      color: isSelected ? AppColors.onSurface : Colors.white,
                      fontSize: Ts.s(context, 21),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasEntries ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── NEXT SESSION HERO CARD ───────────────────────────────────────────────────
// Von Restorff: ONE prominent card for the user's immediate action.

class _NextSessionHeroCard extends StatelessWidget {
  final ScheduleEntry? entry;
  final VoidCallback? onComplete;
  final bool allDone;
  final bool isEmpty;

  const _NextSessionHeroCard({
    required this.entry,
    required this.onComplete,
    required this.allDone,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    // Empty day
    if (isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.event_available_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free day',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: Ts.s(context, 17))),
                  Text('No sessions scheduled',
                      style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: Ts.s(context, 13))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // All done
    if (allDone) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.celebration_rounded,
                  color: AppColors.success, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All done!',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: Ts.s(context, 17))),
                  Text('Every session completed',
                      style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: Ts.s(context, 13))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Next session — hero card with gradient
    final courseColor =
        AppStateProvider.of(context).courseColorOf(entry!.courseId);

    return TapScaleWidget(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E70B8), Color(0xFF154F8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardDark.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEXT SESSION',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: Ts.s(context, 13),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Course name + time
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 52,
                  decoration: BoxDecoration(
                    color: courseColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry!.courseName,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: Ts.s(context, 20),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry!.startTime} – ${entry!.endTime}',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: Ts.s(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // CTA — Serial Position: action at bottom
            AppButton(
              label: 'Complete Session',
              icon: Icons.check_circle_outline_rounded,
              onTap: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STAT MINI CARD ───────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatMiniCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed height prevents uneven cards when label length differs
      height: 88,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardDark.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: Ts.s(context, 19),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: Ts.s(context, 12.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEMESTER BAR ─────────────────────────────────────────────────────────────

class _SemesterBar extends StatelessWidget {
  final AppState state;
  const _SemesterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final current   = state.currentSemesterWeek;
    final total     = state.semesterWeeks;
    final remaining = state.weeksRemaining ?? 0;

    if (current == null || current > total) return const SizedBox.shrink();

    final progress = ((current - 1) / total).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week $current of $total',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: Ts.s(context, 14),
                      ),
                    ),
                    Text(
                      '$remaining wk${remaining == 1 ? '' : 's'} left',
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: Ts.s(context, 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressWidget(
                  value: progress,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EXAM ROW ────────────────────────────────────────────────────────────────

class _ExamRow extends StatelessWidget {
  final AppState state;
  const _ExamRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    final upcoming = state.courses
        .where((c) => c.examDate != null)
        .toList()
      ..sort((a, b) => a.examDate!.compareTo(b.examDate!));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Upcoming Exams'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: upcoming.map((c) {
            final days = DateTime(c.examDate!.year, c.examDate!.month, c.examDate!.day)
                .difference(todayD)
                .inDays;
            final urgent = days >= 0 && days <= 14;
            final label  = days < 0
                ? 'Passed'
                : days == 0
                    ? 'Today!'
                    : days == 1
                        ? '1 day'
                        : days < 14
                            ? '$days days'
                            : '${(days / 7).round()}w';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: urgent
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: urgent ? AppColors.accent : Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.name,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: Ts.s(context, 14),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgent ? AppColors.accent : AppColors.cardDeep,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: Ts.s(context, 13),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── COURSE PROGRESS CARD ────────────────────────────────────────────────────

class _CourseProgressCard extends StatelessWidget {
  final Course course;
  final double progress;
  final double completedHours;
  final int? daysToExam;
  final Color courseColor;
  final VoidCallback onTap;

  const _CourseProgressCard({
    required this.course,
    required this.progress,
    required this.completedHours,
    required this.daysToExam,
    required this.courseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgent  = daysToExam != null && daysToExam! >= 0 && daysToExam! <= 14;

    final Color barColor = courseColor;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color bar
              Container(width: 5, color: courseColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.name,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: Ts.s(context, 16),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Grade badge — neutral, no semantic color
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.targetGrade,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: Ts.s(context, 13),
                              ),
                            ),
                          ),
                          if (urgent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Exam: ${daysToExam}d',
                                style: GoogleFonts.nunito(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: Ts.s(context, 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressWidget(value: progress, color: barColor, height: 7),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${completedHours.toStringAsFixed(1)}h studied',
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: Ts.s(context, 13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: Ts.s(context, 13),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── QUICK ACTION CHIP ───────────────────────────────────────────────────────

// ─── EMPTY HOME ───────────────────────────────────────────────────────────────

class _EmptyHome extends StatelessWidget {
  final void Function(int) onNavTap;
  const _EmptyHome({required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: (size.width * 0.18).clamp(56.0, 80.0),
            color: AppColors.textDark.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No courses yet',
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: Ts.s(context, 20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first course to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark.withValues(alpha: 0.65),
              fontSize: Ts.s(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Add Course',
            icon: Icons.add_rounded,
            onTap: () => onNavTap(2),
          ),
        ],
      ),
    );
  }
}
