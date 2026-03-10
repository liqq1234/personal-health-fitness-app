import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HealthAssessmentCard extends StatelessWidget {
  final int steps;
  final double calories;
  final double sleepHours;

  const HealthAssessmentCard({
    super.key,
    required this.steps,
    required this.calories,
    required this.sleepHours,
  });

  String _getSuggestion() {
    List<String> suggestions = [];
    if (steps < 5000) {
      suggestions.add("您今天的运动量较少，建议进行 20 分钟慢走。");
    } else if (steps > 10000) {
      suggestions.add("太棒了！您今天的步数已达标，请注意肌肉放松。");
    }

    if (sleepHours < 6) {
      suggestions.add("睡眠不足可能导致免疫力下降，今晚请早点休息。");
    } else if (sleepHours > 9) {
      suggestions.add("睡眠时间较长，建议适度运动以保持活力。");
    }

    if (suggestions.isEmpty) {
      return "各项指标正常，持续保持健康的生活习惯。";
    }
    return suggestions.join("\n");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  '健康评估与建议',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.sp),
            Text(
              _getSuggestion(),
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
