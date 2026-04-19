import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';
import 'package:intl/intl.dart';
import '../../core/storage/db_training_helper.dart';
import '../../models/training_state.dart';

class HealthWeeklyChart extends StatefulWidget {
  const HealthWeeklyChart({super.key});

  @override
  State<HealthWeeklyChart> createState() => _HealthWeeklyChartState();
}

class _HealthWeeklyChartState extends State<HealthWeeklyChart> {
  final _dbHelper = DBHealthHelper();
  final _dbTrainingHelper = DBTrainingHelper();

  // 设置加载 14 天数据
  final int _daysToLoad = 14;
  List<DayMetrics> _allData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: _daysToLoad - 1));
    String startStr = DateFormat('yyyy-MM-dd').format(startDate);
    String endStr = DateFormat('yyyy-MM-dd').format(now);

    debugPrint(
      '【DEBUG】HealthWeeklyChart: Loading data from $startStr to $endStr',
    );

    var stepsList = await _dbHelper.queryStepsList(
      startDate: startStr,
      endDate: endStr,
    );
    var sleepList = await _dbHelper.querySleepList(
      startDate: startStr,
      endDate: endStr,
      limit: 200,
    );
    var trainingList = await _dbTrainingHelper.queryTrainedDetailLog(
      startDate: "$startStr 00:00:00",
      endDate: "$endStr 23:59:59",
    );

    List<DayMetrics> tempData = [];
    for (int i = 0; i < _daysToLoad; i++) {
      DateTime date = startDate.add(Duration(days: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      debugPrint('【DEBUG】HealthWeeklyChart: Querying diet for $dateStr');

      double steps = stepsList
          .where((e) => e.date == dateStr)
          .fold(0.0, (sum, item) => sum + item.steps);

      var diets = await _dbHelper.queryDietList(date: dateStr);
      double calories = diets.fold(0.0, (sum, item) => sum + item.calories);

      double sleepHrs = sleepList
          .where(
            (e) => e.endTime.substring(0, 10) == dateStr,
          ) // 改为按结束时间（醒来时间）统计，并使用 substring(0, 10) 兼容 ISO 格式
          .fold(0.0, (sum, item) => sum + item.durationHours);

      double trainMin =
          (trainingList
                      .where(
                        (e) => e.trainedDate.substring(0, 10) == dateStr,
                      ) // 使用 substring(0, 10) 兼容 ISO 格式
                      .fold(0, (sum, item) => sum + item.trainedDuration) /
                  60)
              .ceilToDouble();

      tempData.add(
        DayMetrics(
          dateStr: dateStr,
          steps: steps,
          calories: calories,
          sleep: sleepHrs,
          training: trainMin,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _allData = tempData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return SizedBox(
        height: 200.sp,
        child: const Center(child: CircularProgressIndicator()),
      );

    final colorScheme = Theme.of(context).colorScheme;

    const targetSteps = 10000.0;
    const targetCalories = 2500.0;
    const targetSleep = 8.0;
    const targetTraining = 60.0;

    // 关键优化：根据屏幕宽度动态计算每一天的宽度，确保一个屏幕只展示 3 天
    // 1.sw 代表屏幕宽度，减去外部 Card 的纵向边距（通常左右各 16sp）
    double chartVisibleWidth = 1.sw - 32.sp;
    double dayWidth = chartVisibleWidth / 3;
    double totalChartWidth = _allData.length * dayWidth;

    // 计算所有数据的最大比率，用于动态设置Y轴范围
    double maxRatio = 0;
    for (final data in _allData) {
      double stepsRatio = data.steps / targetSteps;
      double caloriesRatio = data.calories / targetCalories;
      double sleepRatio = data.sleep / targetSleep;
      double trainingRatio = data.training / targetTraining;

      maxRatio = stepsRatio > maxRatio ? stepsRatio : maxRatio;
      maxRatio = caloriesRatio > maxRatio ? caloriesRatio : maxRatio;
      maxRatio = sleepRatio > maxRatio ? sleepRatio : maxRatio;
      maxRatio = trainingRatio > maxRatio ? trainingRatio : maxRatio;
    }

    // 设置maxY为最大比率向上取整到0.1的倍数，再加0.1作为余量
    // 最小值为0.2，确保即使所有数据为0也有合理的显示范围
    double maxY = ((maxRatio * 10).ceilToDouble() / 10).clamp(0.2, 1.2);
    if (maxY - maxRatio < 0.1) {
      maxY += 0.1;
      if (maxY > 1.2) maxY = 1.2; // 限制最大为1.2，保持一致性
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sp),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('步数', Colors.green),
                SizedBox(width: 8.sp),
                _buildLegend('饮食', Colors.orange),
                SizedBox(width: 8.sp),
                _buildLegend('睡眠', Colors.blue),
                SizedBox(width: 8.sp),
                _buildLegend('训练', Colors.teal),
              ],
            ),
          ),
          Container(
            height: 220.sp,
            padding: EdgeInsets.only(bottom: 8.sp),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // 初始位置靠右，即显示“今日”
              child: Container(
                width: totalChartWidth,
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            colorScheme.primaryContainer.withOpacity(0.9),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          var data = _allData[groupIndex];
                          String label = "";
                          String val = "";
                          if (rodIndex == 0) {
                            label = "步数";
                            val = "${data.steps.toInt()}步";
                          } else if (rodIndex == 1) {
                            label = "饮食";
                            val = "${data.calories.toInt()}kcal";
                          } else if (rodIndex == 2) {
                            label = "睡眠";
                            val = "${data.sleep.toStringAsFixed(1)}h";
                          } else if (rodIndex == 3) {
                            label = "训练";
                            val = "${data.training.toInt()}min";
                          }
                          return BarTooltipItem(
                            "$label\n$val",
                            TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int idx = value.toInt();
                            if (idx < 0 || idx >= _allData.length)
                              return const SizedBox();
                            String dateStr = _allData[idx].dateStr;
                            bool isToday =
                                dateStr ==
                                DateFormat('yyyy-MM-dd').format(DateTime.now());
                            return Padding(
                              padding: EdgeInsets.only(top: 8.sp),
                              child: Text(
                                isToday ? "今日" : dateStr.substring(5),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          reservedSize: 24.sp,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _allData.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var d = entry.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          _buildRod(d.steps / targetSteps, Colors.green, maxY),
                          _buildRod(
                            d.calories / targetCalories,
                            Colors.orange,
                            maxY,
                          ),
                          _buildRod(d.sleep / targetSleep, Colors.blue, maxY),
                          _buildRod(
                            d.training / targetTraining,
                            Colors.teal,
                            maxY,
                          ),
                        ],
                        barsSpace: 2.sp,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartRodData _buildRod(double ratio, Color color, double maxY) {
    double val = ratio > maxY ? maxY : ratio;
    // 确保即使数据为0也有最小可见高度
    if (val == 0) {
      val = 0.02; // 为0值数据设置最小可见高度
    } else if (val < 0.05 && ratio > 0) {
      val = 0.05; // 为微小正值设置最小高度
    }
    return BarChartRodData(
      toY: val,
      color: color,
      width: 10.sp, // 增加单根柱子宽度，因为现在屏幕只放 3 天，空间充裕
      borderRadius: BorderRadius.circular(2.sp),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: maxY,
        color: color.withOpacity(0.04),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.sp,
          height: 6.sp,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 3.sp),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class DayMetrics {
  final String dateStr;
  final double steps;
  final double calories;
  final double sleep;
  final double training;
  DayMetrics({
    required this.dateStr,
    required this.steps,
    required this.calories,
    required this.sleep,
    required this.training,
  });
}
