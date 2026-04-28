import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import '../services/calendar_service.dart';
import 'profile_screen.dart';

// Shared time picker: 24-hour dial, no AM/PM, dark Cancel/OK.
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

class CalendarScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  const CalendarScreen({super.key, required this.onNavTap});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime get _today => DateTime.now();

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    // Pad with leading empty days (Mon=0 offset)
    final startWeekday = (first.weekday - 1) % 7; // 0=Mon
    final days = <DateTime>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(DateTime(0)); // placeholder
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    return days;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final size = MediaQuery.of(context).size;
    final double hPad = (size.width * 0.05).clamp(14.0, 40.0);
    final entries = state.entriesForDay(_selectedDay);
    final daysWithEntries = state.daysWithEntries;
    final days = _daysInMonth(_focusedMonth);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          buildAppBar(
            context,
            'CALENDAR',
            showBack: false,
            trailing: ProfileIconButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  // Calendar card
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      children: [
                        // Month header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded,
                                  color: Colors.white),
                              onPressed: _prevMonth,
                              visualDensity: VisualDensity.compact,
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_focusedMonth.year}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: Ts.s(context, 13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM').format(_focusedMonth),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: Ts.s(context, 18),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white),
                              onPressed: _nextMonth,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Weekday headers
                        Row(
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((d) => Expanded(
                                    child: Text(
                                      d,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontWeight: FontWeight.w700,
                                        fontSize: Ts.s(context, 13),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),

                        const SizedBox(height: 4),

                        // Days grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: days.length,
                          itemBuilder: (context, i) {
                            final day = days[i];
                            if (day.year == 0) return const SizedBox();

                            final isToday = day.year == _today.year &&
                                day.month == _today.month &&
                                day.day == _today.day;
                            final isSelected = day.year == _selectedDay.year &&
                                day.month == _selectedDay.month &&
                                day.day == _selectedDay.day;
                            final hasDot = daysWithEntries.any((d) =>
                                d.year == day.year &&
                                d.month == day.month &&
                                d.day == day.day);

                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppColors.cardDark.withValues(alpha: 0.45)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.cardDark
                                            : Colors.white,
                                        fontWeight: isSelected || isToday
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: Ts.s(context, 14),
                                      ),
                                    ),
                                    if (hasDot)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.7)
                                              : AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sessions for selected day
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE, d MMM').format(_selectedDay),
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: Ts.s(context, 16),
                        ),
                      ),
                      TapScaleWidget(
                        onTap: () => _showAddEntryDialog(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardDark.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Add session',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: Ts.s(context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'No sessions — tap + to add one',
                              style: TextStyle(
                                color: AppColors.textDark.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: Ts.s(context, 14),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final entry = entries[i];
                              return Dismissible(
                                key: ValueKey(entry.id),
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 24),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.white, size: 24),
                                ),
                                confirmDismiss: (dir) async {
                                  if (dir == DismissDirection.startToEnd) {
                                    state.toggleEntryComplete(entry.id);
                                    return false;
                                  }
                                  return true;
                                },
                                onDismissed: (_) =>
                                    state.deleteScheduleEntry(entry.id),
                                child: _CalendarEntryTile(entry: entry),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEntryDialog(
      BuildContext context, AppState state) async {
    if (state.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a course first in the Courses tab')),
      );
      return;
    }

    Course selectedCourse = state.courses.first;
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);

    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Add Study Session',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(ctx, 18),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Course',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: Ts.s(ctx, 15)),
                    ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Course>(
                      value: selectedCourse,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: Ts.s(ctx, 16),
                      ),
                      items: state.courses
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (c) {
                        if (c != null) {
                          setDialogState(() => selectedCourse = c);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerBtn(
                        label: 'Start',
                        time: startTime,
                        onPick: () async {
                          final t = await _pickTime(context, startTime);
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimePickerBtn(
                        label: 'End',
                        time: endTime,
                        onPick: () async {
                          final t = await _pickTime(context, endTime);
                          if (t != null) setDialogState(() => endTime = t);
                        },
                      ),
                    ),
                  ],
                ),
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
                  state.addScheduleEntry(ScheduleEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    courseId: selectedCourse.id,
                    courseName: selectedCourse.name,
                    date: _selectedDay,
                    startTime: fmt(startTime),
                    endTime: fmt(endTime),
                  ));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarEntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  const _CalendarEntryTile({required this.entry});

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(
        hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _weekdayName(int wd) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];

  Future<void> _showEditDialog(BuildContext context, AppState state) async {
    TimeOfDay startTime = _parseTime(entry.startTime);
    TimeOfDay endTime = _parseTime(entry.endTime);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Edit Session',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: Ts.s(ctx, 18),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.courseName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: Ts.s(ctx, 16),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerBtn(
                        label: 'Start',
                        time: startTime,
                        onPick: () async {
                          final t = await _pickTime(context, startTime);
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimePickerBtn(
                        label: 'End',
                        time: endTime,
                        onPick: () async {
                          final t = await _pickTime(context, endTime);
                          if (t != null) setDialogState(() => endTime = t);
                        },
                      ),
                    ),
                  ],
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
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final newStart = _fmtTime(startTime);
    final newEnd = _fmtTime(endTime);

    // If auto-generated, ask: just this one or this + all future on same weekday
    if (entry.id.contains('_auto_')) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Recurring Session',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: Ts.s(ctx, 18),
            ),
          ),
          content: Text(
            'Do you want to change only this session, or this and all future ${_weekdayName(entry.date.weekday)} sessions for ${entry.courseName}?',
            style: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.85),
              fontSize: Ts.s(ctx, 15),
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: Ts.s(ctx, 14))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'one'),
              child: Text(
                'Just this one',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: Ts.s(ctx, 15),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'future'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'This + future',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: Ts.s(ctx, 15),
                ),
              ),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;
      if (!context.mounted) return;

      if (choice == 'one') {
        await state.updateScheduleEntry(
            entry.copyWith(startTime: newStart, endTime: newEnd));
      } else {
        await state.updateFutureWeekdaySessions(
            entry.courseId, entry.date.weekday, entry.date, newStart, newEnd);
      }
    } else {
      await state.updateScheduleEntry(
          entry.copyWith(startTime: newStart, endTime: newEnd));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final courseColor = state.courseColorOf(entry.courseId);

    return TapScaleWidget(
      onTap: () => _showEditDialog(context, state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: entry.completed
              ? AppColors.card.withValues(alpha: 0.55)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: entry.completed
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: entry.completed
              ? null
              : [
                  BoxShadow(
                    color: AppColors.cardDark.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 5,
                color: entry.completed
                    ? courseColor.withValues(alpha: 0.35)
                    : courseColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: entry.completed
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: Ts.s(context, 15),
                                decoration: entry.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              child: Text(entry.courseName),
                            ),
                            Text(
                              '${entry.startTime} – ${entry.endTime}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: Ts.s(context, 13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Checkbox
                      GestureDetector(
                        onTap: () => state.toggleEntryComplete(entry.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: entry.completed
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: entry.completed
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          child: entry.completed
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 15)
                              : null,
                        ),
                      ),
                      // Export to calendar
                      GestureDetector(
                        onTap: () => _exportToCalendar(context),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.calendar_today_rounded,
                              color: Colors.white.withValues(alpha: 0.65), size: 18),
                        ),
                      ),
                      // Delete
                      GestureDetector(
                        onTap: () => state.deleteScheduleEntry(entry.id),
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.65), size: 20),
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

  Future<void> _exportToCalendar(BuildContext context) async {
    final result = await CalendarService.instance.addEvent(entry);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? 'Added to calendar'
          : result.errorMessage ?? 'Unknown error'),
      backgroundColor:
          result.success ? AppColors.success : Colors.redAccent,
      duration: const Duration(seconds: 4),
    ));
  }
}

class _TimePickerBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;

  const _TimePickerBtn(
      {required this.label, required this.time, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: Ts.s(context, 14),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(formatted,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: Ts.s(context, 16),
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
