import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../widgets/shared_widgets.dart';

class StatsScreen extends StatelessWidget {
  final void Function(int) onNavTap;
  const StatsScreen({super.key, required this.onNavTap});

  static double _dur(String s, String e) {
    double toH(String t) {
      final p = t.split(':');
      return (int.tryParse(p[0]) ?? 0) + (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0) / 60.0;
    }
    return (toH(e) - toH(s)).clamp(0.0, 24.0);
  }

  /// Hours studied per week for the last [count] weeks (oldest → newest).
  List<_WeekBar> _weeklyBars(AppState state, int count) {
    final now = DateTime.now();
    final thisMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final Map<DateTime, double> map = {};
    for (final e in state.schedule) {
      if (!e.completed) continue;
      final mon = e.date.subtract(Duration(days: e.date.weekday - 1));
      final key = DateTime(mon.year, mon.month, mon.day);
      map[key] = (map[key] ?? 0) + _dur(e.startTime, e.endTime);
    }

    return List.generate(count, (i) {
      final mon = thisMonday.subtract(Duration(days: (count - 1 - i) * 7));
      final key = DateTime(mon.year, mon.month, mon.day);
      return _WeekBar(monday: mon, hours: map[key] ?? 0);
    });
  }

  double _totalHours(AppState state) => state.schedule
      .where((e) => e.completed)
      .fold(0.0, (s, e) => s + _dur(e.startTime, e.endTime));

  int _totalSessions(AppState state) =>
      state.schedule.where((e) => e.completed).length;

  double _bestWeek(AppState state) {
    final Map<DateTime, double> map = {};
    for (final e in state.schedule) {
      if (!e.completed) continue;
      final mon = e.date.subtract(Duration(days: e.date.weekday - 1));
      final key = DateTime(mon.year, mon.month, mon.day);
      map[key] = (map[key] ?? 0) + _dur(e.startTime, e.endTime);
    }
    return map.values.fold(0.0, (m, v) => v > m ? v : m);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final size = MediaQuery.of(context).size;
    final hPad = (size.width * 0.05).clamp(14.0, 40.0);

    final streak   = state.studyStreak;
    final totalH   = _totalHours(state);
    final sessions = _totalSessions(state);
    final bestW    = _bestWeek(state);
    final bars     = _weeklyBars(state, 6);
    final maxBar   = bars.fold(0.0, (m, b) => b.hours > m ? b.hours : m);

    // Hours per course — includes hoursStudiedSoFar for catch-up courses
    final totalTracked = state.courses.fold(
        0.0, (sum, c) => sum + state.effectiveCompletedHours(c));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          buildAppBar(context, 'STATISTICS', showBack: false),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
              physics: const BouncingScrollPhysics(),
              children: [

                // ── Row 1: streak + total hours ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: streak > 0
                            ? const Color(0xFFFF6B35)
                            : Colors.white38,
                        value: '$streak',
                        label: 'day streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.menu_book_rounded,
                        iconColor: AppColors.cardDark,
                        value: totalH.toStringAsFixed(1),
                        label: 'hours total',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Row 2: sessions completed + best week ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        value: '$sessions',
                        label: 'sessions done',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFFF39C12),
                        value: bestW.toStringAsFixed(1),
                        label: 'best week (h)',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Weekly bar chart ───────────────────────────────────────────
                const _SectionHeader(label: 'Hours per week', subtitle: 'Completed study hours each week'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                  ),
                  child: state.schedule.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No sessions yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                                fontSize: Ts.s(context, 14),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: 100,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: bars.map((b) {
                                  final frac = maxBar > 0
                                      ? (b.hours / maxBar).clamp(0.0, 1.0)
                                      : 0.0;
                                  final isThisWeek = b.monday.isAtSameMomentAs(
                                    DateTime.now().subtract(Duration(
                                        days: DateTime.now().weekday - 1))
                                        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
                                  );
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (b.hours > 0)
                                            Text(
                                              b.hours.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                                fontSize: Ts.s(context, 15),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 400),
                                            height: frac * 72,
                                            decoration: BoxDecoration(
                                              color: isThisWeek
                                                  ? AppColors.accent
                                                  : AppColors.cardDark,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: bars.map((b) => Expanded(
                                    child: Text(
                                      DateFormat('d/M').format(b.monday),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        fontSize: Ts.s(context, 15),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )).toList(),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 14),

                // ── Time by course (merged: actual h + goal h) ────────────────
                if (state.courses.isNotEmpty) ...[
                  const _SectionHeader(
                    label: 'Time by course',
                    subtitle: 'Hours studied vs. goal for each course',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Column(
                      children: (() {
                        final sorted = state.courses.map((c) {
                          return MapEntry(c, state.effectiveCompletedHours(c));
                        }).toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        return sorted.map((entry) {
                          final course   = entry.key;
                          final hours    = entry.value;
                          final color    = state.courseColorOf(course.id);
                          final required = state.requiredHoursForCourse(course);
                          // Progress bar: against goal if available, else against total studied
                          final frac = required != null && required > 0
                              ? (hours / required).clamp(0.0, 1.0)
                              : (totalTracked > 0 ? (hours / totalTracked).clamp(0.0, 1.0) : 0.0);
                          final label = required != null
                              ? '${hours.toStringAsFixed(1)}h / ${required.toStringAsFixed(1)}h'
                              : '${hours.toStringAsFixed(1)}h';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10, height: 10,
                                      margin: const EdgeInsets.only(right: 7),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        course.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: Ts.s(context, 15),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w700,
                                        fontSize: Ts.s(context, 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: frac,
                                    minHeight: 7,
                                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      })(),
                    ),
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

class _WeekBar {
  final DateTime monday;
  final double hours;
  const _WeekBar({required this.monday, required this.hours});
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: iconColor,
              size: Ts.s(context, 28)),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: Ts.s(context, 22),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: Ts.s(context, 13),
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? subtitle;
  const _SectionHeader({required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: Ts.s(context, 19),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
              fontSize: Ts.s(context, 14),
            ),
          ),
      ],
    );
  }
}
