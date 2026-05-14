import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../state/app_state.dart';

class DayPickerStrip extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final AppState state;

  const DayPickerStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.state,
  });

  static DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = _monday(today);
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Row(
      children: days.map((day) {
        final isToday = day.year == today.year &&
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
