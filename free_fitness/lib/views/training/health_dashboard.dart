import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/health_models.dart';
import '../../services/pedometer_service.dart';
import '../../core/storage/db_health_helper.dart';
import '../dietary/diet_entry.dart';
import '../diary/sleep_report.dart';
import '../diary/sleep_entry.dart';
import '../../services/sync_service.dart';
import '../../core/storage/db_user_helper.dart';
import '../../core/storage/db_training_helper.dart';
import '../../core/storage/db_dietary_helper.dart';
import '../../models/training_state.dart';
import '../../models/dietary_state.dart';
import '../../models/user_state.dart';
import '../../models/cus_app_localizations.dart';
import '../../services/training_schedule_service.dart';
import '../../core/constants/constants.dart';
import 'health_weekly_chart.dart';
import 'health_assessment_card.dart';
import '../me/weight_change_record/index.dart';
import 'index.dart'; // 为了跳转到训练页

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => HealthDashboardState();
}

class HealthDashboardState extends State<HealthDashboard> {
  final _pedometerService = PedometerService();
  final _dbHelper = DBHealthHelper();
  final _dbTrainingHelper = DBTrainingHelper();
  int _steps = 0;
  double _sleepHours = 0;
  double _dietCalories = 0;
  int _trainingMinutes = 0;
  double _exerciseCalories = 0;
  List<TrainingSchedule> _todaySchedules = [];
  bool _hasTrainingLogs = false;
  double _rdaGoal = 2000;
  User? _currentUser;
  StreamSubscription<int>? _stepSubscription;

  @override
  void initState() {
    super.initState();
    _initHealth();
    // 监听步数实时变化
    _stepSubscription = _pedometerService.stepStream.listen((steps) {
      if (mounted) {
        setState(() {
          _steps = steps;
        });
      }
    });
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initHealth() async {
    await _pedometerService.initPedometer();
    var sleepRecords = await _dbHelper.querySleepList(limit: 1);
    var todayStr = DateTime.now().toIso8601String().split('T')[0];

    // 使用简单的饮食日志记录当天的卡路里（仅用于仪表盘顶部展示）
    var dietLogs = await _dbHelper.queryDietList(date: todayStr);

    // 获取用户信息以获取 RDA 和体重
    var user = await DBUserHelper().queryUser(userId: CacheUser.userId);
    _currentUser = user;
    if (user != null) {
      _rdaGoal = user.rdaGoal?.toDouble() ?? 2000;
    }

    // 获取今日排程
    try {
      _todaySchedules = await TrainingScheduleService.getDailySchedules(
        CacheUser.userId,
        todayStr,
      );
    } catch (e) {
      debugPrint('获取今日排程失败: $e');
    }

    // 获取最近 7 天详细饮食数据以生成建议 (同时使用 DBDietaryHelper 和 DBHealthHelper)
    var sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    var sevenDaysAgoStr = sevenDaysAgo.toIso8601String().split('T')[0];

    // 详细请求 (Cloud)
    var recentDietDetails = await DBDietaryHelper()
        .queryDailyFoodItemListWithDetail(
          userId: CacheUser.userId,
          startDate: sevenDaysAgoStr,
          endDate: todayStr,
          withDetail: true,
        );

    // 简易请求 (Local)
    var recentDietLogs = await _dbHelper.queryDietList(
      startDate: sevenDaysAgoStr,
      endDate: todayStr,
    );

    // 查询今日运动记录
    var trainingLogs = await _dbTrainingHelper.queryTrainedDetailLog(
      userId: CacheUser.userId,
      startDate: todayStr,
      endDate: todayStr,
    );

    if (mounted) {
      setState(() {
        _steps = _pedometerService.todaySteps;
        if (sleepRecords.isNotEmpty) {
          _sleepHours = sleepRecords.first.durationHours;
        }
        _dietCalories = dietLogs.fold(0.0, (sum, item) => sum + item.calories);

        // 计算总锻炼时间（秒转分钟）
        int totalSeconds = trainingLogs.fold(
          0,
          (sum, item) => sum + item.trainedDuration,
        );
        _trainingMinutes = (totalSeconds / 60).ceil();

        // 计算今日运动消耗的卡路里（从 TrainedDetailLog 的 consumption 字段）
        _exerciseCalories = trainingLogs.fold(
          0.0,
          (sum, item) => sum + (item.consumption ?? 0),
        );
        _hasTrainingLogs = trainingLogs.isNotEmpty;
      });
    }
  }

  void refresh() {
    _initHealth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日状态')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
          child: Column(
            children: [
              _buildMainCard(),
              SizedBox(height: 12.sp),
              _buildWeightTrendModule(),
              SizedBox(height: 12.sp),
              const HealthWeeklyChart(),
              HealthAssessmentCard(
                steps: _steps,
                sleepHours: _sleepHours,
                todaySchedules: _todaySchedules,
                hasTrainingLogs: _hasTrainingLogs,
              ),
              SizedBox(height: 8.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sp),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16.sp),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        "今日 / Today",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      GestureDetector(
                        onTap: () async {
                          await _pedometerService.manualAddSteps(1000);
                          _initHealth();
                        },
                        child: Text(
                          '$_steps',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 48.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        "步数 Steps",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: '数据同步',
                        icon: Icon(
                          Icons.sync,
                          color: colorScheme.primary,
                          size: 20.sp,
                        ),
                        onPressed: () async {
                          await SyncService().syncData();
                          await SyncService().pullSteps();
                          _initHealth();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  Icons.local_fire_department,
                  '${_dietCalories.toStringAsFixed(0)}',
                  'kcal(进食)',
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SleepReportPage(),
                    ),
                  ).then((_) => _initHealth()),
                  child: _buildMetric(
                    Icons.bedtime,
                    '${_sleepHours.toStringAsFixed(1)}',
                    'h(睡眠)',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(Icons.timer, '$_trainingMinutes', 'min(训练时长)'),
                _buildMetric(
                  Icons.directions_run,
                  '${(_exerciseCalories + _steps * 0.04).toStringAsFixed(0)}',
                  'kcal(消耗)',
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            Divider(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              height: 1,
            ),
            SizedBox(height: 12.sp),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => DietEntryPage()),
            ).then((_) => _initHealth()),
            icon: const Icon(Icons.restaurant),
            label: const Text('记饮食'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.sp),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.sp),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => SleepEntryPage()),
            ).then((_) => _initHealth()),
            icon: const Icon(Icons.bed),
            label: const Text('记睡眠'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.sp),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.sp),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const Training()),
            ).then((_) => _initHealth()),
            icon: const Icon(Icons.fitness_center),
            label: const Text('去训练'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightTrendModule() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _currentUser;
    if (user == null) return const SizedBox();

    final weight = user.currentWeight ?? 0;
    final height = (user.height ?? 0) / 100;
    final bmi = (height == 0) ? 0.0 : (weight / (height * height));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => WeightChangeRecord(userInfo: user)),
      ).then((_) => _initHealth()),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.sp),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: colorScheme.onSecondaryContainer,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "体重趋势 / Weight Trend",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Row(
                      children: [
                        Text(
                          "${weight.toStringAsFixed(1)} kg",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.sp,
                            vertical: 2.sp,
                          ),
                          decoration: BoxDecoration(
                            color: _getBmiColor(bmi).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                          child: Text(
                            "BMI: ${bmi.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: _getBmiColor(bmi),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 28) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetric(IconData icon, String value, String unit) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 16.sp),
        SizedBox(width: 4.sp),
        Text(
          '$value $unit',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
