import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../state/app_state.dart';
import '../shared_widgets.dart';

class ExamRow extends StatelessWidget {
  final AppState state;
  const ExamRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    final upcoming = state.courses.where((c) => c.examDate != null).toList()
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
            final days =
                DateTime(c.examDate!.year, c.examDate!.month, c.examDate!.day)
                    .difference(todayD)
                    .inDays;
            final urgent = days >= 0 && days <= 14;
            final label = days < 0
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
                  color: urgent
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.18),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
