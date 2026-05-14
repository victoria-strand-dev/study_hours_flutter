import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_text.dart';
import '../../state/app_state.dart';
import '../shared_widgets.dart';

class SemesterBar extends StatelessWidget {
  final AppState state;
  const SemesterBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final current = state.currentSemesterWeek;
    final total = state.semesterWeeks;
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
