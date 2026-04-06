import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widgets/cus_cards.dart';
import '../../core/constants/constants.dart';
import '../../models/cus_app_localizations.dart';
import 'exercise_tracking.dart';
import 'reports/index.dart';
import 'schedule_training_page.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(CusAL.of(context).training)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
              child: Column(
                children: [
                  CusCoverCard(
                    targetPage: const TrainingReports(),
                    title: CusAL.of(context).trainingReports,
                    subtitle: CusAL.of(context).trainingReportsSubtitle,
                    imageUrl: reportImageUrl,
                  ),
                  SizedBox(height: 8.sp),
                  CusCoverCard(
                    targetPage: const ExerciseTracking(),
                    title: '运动追踪',
                    subtitle: '实时记录运动轨迹与数据',
                    imageUrl: workoutWomanImageUrl,
                  ),
                  SizedBox(height: 8.sp),
                  CusCoverCard(
                    targetPage: const ScheduleTrainingPage(),
                    title: '训练计划',
                    subtitle: '管理并执行个人训练内容',
                    imageUrl: workoutCalendarImageUrl,
                  ),
                  SizedBox(height: 20.sp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
