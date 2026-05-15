import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../state/app_state.dart';
import '../../models/models.dart';
import '../shared_widgets.dart';
import '../buttons/time_picker_btn.dart';

class CalendarEntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  const CalendarEntryTile({super.key, required this.entry});

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.5),
                              ),
                              child: Text(
                                entry.label.isNotEmpty
                                    ? '${entry.courseName} · ${entry.label}'
                                    : entry.courseName,
                              ),
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
                      GestureDetector(
                        onTap: () => state.deleteScheduleEntry(entry.id),
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.65),
                            size: 20),
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
