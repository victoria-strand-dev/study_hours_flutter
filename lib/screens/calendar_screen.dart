import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../state/app_state.dart';
import '../models/models.dart';

import '../widgets/shared_widgets.dart';
import '../widgets/cards/calendar_month_card.dart';
import '../widgets/calendar/calendar_entry_tile.dart';
import '../widgets/buttons/time_picker_btn.dart';

import 'profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  final void Function(int) onNavTap;
  const CalendarScreen({super.key, required this.onNavTap});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final startWeekday = (first.weekday - 1) % 7;
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
                  CalendarMonthCard(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    days: days,
                    daysWithEntries: daysWithEntries,
                    onPrevMonth: _prevMonth,
                    onNextMonth: _nextMonth,
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                  ),
                  const SizedBox(height: 12),
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
                                color:
                                    AppColors.cardDark.withValues(alpha: 0.25),
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
                                color:
                                    AppColors.textDark.withValues(alpha: 0.5),
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
                              return CalendarEntryTile(entry: entry);
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

//<3<3<3<3<3<3<3<3<3<3 Add new session if day is empty <3<3<3<3<3<3<3<3<3<3<3
  Future<void> _showAddEntryDialog(BuildContext context, AppState state) async {
    if (state.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a course first in the Courses tab')),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        fontSize: Ts.s(ctx, 15))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18), width: 1),
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
                      child: TimePickerBtn(
                        label: 'Start',
                        time: startTime,
                        onPick: () async {
                          final t = await pickTime(context, startTime);
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TimePickerBtn(
                        label: 'End',
                        time: endTime,
                        onPick: () async {
                          final t = await pickTime(context, endTime);
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
