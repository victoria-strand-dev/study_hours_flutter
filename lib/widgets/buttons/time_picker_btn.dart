import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) {
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

class TimePickerBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;

  const TimePickerBtn({
    super.key,
    required this.label,
    required this.time,
    required this.onPick,
  });

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
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: Ts.s(context, 14),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              formatted,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: Ts.s(context, 16),
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
