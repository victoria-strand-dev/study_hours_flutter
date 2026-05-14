import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../state/app_state.dart';
import '../../models/models.dart';
import '../shared_widgets.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClearSchedule;

  const CourseCard({
    super.key,
    required this.course,
    required this.onSchedule,
    required this.onEdit,
    required this.onDelete,
    required this.onClearSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final courseColor = state.courseColorOf(course.id);
    final creditsStr = course.credits % 1 == 0
        ? course.credits.toInt().toString()
        : course.credits.toString();
    final daysLabel =
        course.daysPerWeek == 1 ? '1 day' : '${course.daysPerWeek} days';

    final completed = state.effectiveCompletedHours(course);
    final required = state.requiredHoursForCourse(course);
    final hasProgress = required != null && required > 0;
    final progress = hasProgress ? (completed / required).clamp(0.0, 1.0) : 0.0;
    final done = hasProgress && progress >= 1.0;

    // Dynamic weekly hours (recalculated from actual progress + time left)
    final dynWeekly = state.dynamicWeeklyHours(course);
    final weeksLeft = state.weeksRemainingForCourse(course);
    final String resultText;
    if (done) {
      resultText = 'Goal reached for ${course.targetGrade}!';
    } else if (dynWeekly != null && dynWeekly <= 0) {
      resultText = 'Hours target reached for ${course.targetGrade}';
    } else if (dynWeekly != null && weeksLeft != null && weeksLeft > 0) {
      resultText = '${dynWeekly.toStringAsFixed(1)}h/week needed '
          '(${weeksLeft}w left) → ${course.targetGrade}';
    } else if (course.hoursPerDay <= 0 && course.hoursMode) {
      resultText = 'Hours target reached for ${course.targetGrade}';
    } else if (course.hoursMode) {
      resultText = 'Need ${course.hoursPerDay.toStringAsFixed(1)}h, '
          '$daysLabel/week → ${course.targetGrade}';
    } else {
      resultText = '${course.hoursPerDay.toStringAsFixed(1)}h, '
          '$daysLabel/week → Expected ${course.targetGrade}';
    }

    //<3<3<3<3<3<3<3<3 Grade updtae check <3<3<3<3<3<3<3<3
    final upgradeGrade = state.achievableUpgradeGrade(course);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: done ? courseColor : Colors.white.withValues(alpha: 0.18),
            width: done ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardDark.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 10, color: courseColor),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${course.name} | $creditsStr credits',
                            style: AppText.cardTitleLight,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            resultText,
                            style: AppText.bodyLight.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          if (course.examDate != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Exam: ${DateFormat('d MMM yyyy').format(course.examDate!)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: Ts.s(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (hasProgress) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.22),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(courseColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              done
                                  ? 'Goal reached! ${completed.toStringAsFixed(1)}h completed'
                                  : '${completed.toStringAsFixed(1)}h / ${required.toStringAsFixed(1)}h completed',
                              style: TextStyle(
                                color: done
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontSize: done
                                    ? Ts.s(context, 15)
                                    : Ts.s(context, 14),
                                fontWeight:
                                    done ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ],
                          if (upgradeGrade != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'At this pace you\'re on track for a $upgradeGrade',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: Ts.s(context, 13),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white70, size: 20),
                      color: AppColors.bg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        if (v == 'schedule') onSchedule();
                        if (v == 'edit') onEdit();
                        if (v == 'clear') onClearSchedule();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'schedule',
                          child: MenuRow(
                              icon: Icons.calendar_month_rounded,
                              label: 'Add to calendar'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: MenuRow(
                              icon: Icons.edit_rounded, label: 'Edit course'),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: MenuRow(
                              icon: Icons.event_busy_rounded,
                              label: 'Clear schedule',
                              destructive: true),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: MenuRow(
                              icon: Icons.delete_rounded,
                              label: 'Delete course',
                              destructive: true),
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
    );
  }
}
