import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../models/models.dart';
import '../shared_widgets.dart';

class CourseProgressCard extends StatelessWidget {
  final Course course;
  final double progress;
  final double completedHours;
  final int? daysToExam;
  final Color courseColor;
  final VoidCallback onTap;

  const CourseProgressCard({
    super.key,
    required this.course,
    required this.progress,
    required this.completedHours,
    required this.daysToExam,
    required this.courseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = daysToExam != null && daysToExam! >= 0 && daysToExam! <= 14;

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
                      ProgressWidget(
                          value: progress, color: courseColor, height: 7),
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
