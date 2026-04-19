import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/training_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cus_app_localizations.dart';

class HealthAssessmentCard extends StatelessWidget {
  final int steps;
  final double sleepHours;
  final bool hasTrainingLogs;
  final List<TrainingSchedule> todaySchedules;

  const HealthAssessmentCard({
    super.key,
    required this.steps,
    required this.sleepHours,
    required this.todaySchedules,
    this.hasTrainingLogs = false,
  });

  Widget _buildAssessmentItem(
    BuildContext context,
    String label,
    String status,
    bool isDone,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.error_outline,
            color: isDone ? Colors.green : Colors.orange,
            size: 18.sp,
          ),
          SizedBox(width: 8.sp),
          Icon(icon, size: 18.sp, color: theme.colorScheme.primary),
          SizedBox(width: 8.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final al = CusAL.of(context);

    // 检查各项达标情况
    bool stepsDone = steps >= 10000;
    bool sleepDone = sleepHours >= 8.0;
    bool trainingDone =
        hasTrainingLogs ||
        (todaySchedules.isNotEmpty &&
            todaySchedules.every((s) => s.status == 'COMPLETED'));

    // 如果没跟练且没排程，且步数和睡眠都不足，可能就不显示已完成，但根据用户要求，我们要明确状态
    String trainingStatusText = trainingDone
        ? al.trainingCompleted
        : al.trainingPending;
    if (todaySchedules.isEmpty && !hasTrainingLogs) {
      trainingStatusText = al.noTrainingScheduled;
    }

    return Card(
      margin: EdgeInsets.all(10.sp),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: colorScheme.primary),
                SizedBox(width: 8.sp),
                Text(
                  al.healthAssessmentDetail,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            _buildAssessmentItem(
              context,
              al.stepsStatus,
              '$steps / 10000',
              stepsDone,
              Icons.directions_walk,
            ),
            _buildAssessmentItem(
              context,
              al.trainingStatus,
              trainingStatusText,
              trainingDone,
              Icons.fitness_center,
            ),
            _buildAssessmentItem(
              context,
              al.sleepStatus,
              '${sleepHours.toStringAsFixed(1)} / 8.0 h',
              sleepDone,
              Icons.bedtime,
            ),
          ],
        ),
      ),
    );
  }
}
