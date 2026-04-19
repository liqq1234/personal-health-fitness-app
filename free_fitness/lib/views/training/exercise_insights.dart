import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/storage/db_health_helper.dart';
import '../../core/constants/constants.dart';
import '../../core/storage/db_training_helper.dart';
import '../../models/training_state.dart';
import 'package:intl/intl.dart';

class ExerciseInsightsPage extends StatefulWidget {
  final bool showAppBar;
  const ExerciseInsightsPage({super.key, this.showAppBar = true});

  @override
  State<ExerciseInsightsPage> createState() => _ExerciseInsightsPageState();
}

class _ExerciseInsightsPageState extends State<ExerciseInsightsPage> {
  Map<String, dynamic>? _analysis;
  List<TrainedDetailLog> _localLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 页面进入时自动加载缓存数据（不耗Token）
    _loadAnalysis(force: false);
  }

  Future<void> _loadAnalysis({bool force = false}) async {
    setState(() => _isLoading = true);

    // 同时获取云端分析和本地原始日志
    final results = await Future.wait([
      DBHealthHelper().getExerciseAnalysis(force: force),
      DBTrainingHelper().queryTrainedDetailLog(
        userId: CacheUser.userId,
        startDate:
            DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now().subtract(const Duration(days: 14))) +
            " 00:00:00",
        endDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        gmtCreateSort: "DESC",
      ),
    ]);

    final analysisResponse = results[0] as Map<String, dynamic>?;
    final logsResponse = results[1] as List<TrainedDetailLog>;

    if (mounted) {
      setState(() {
        if (analysisResponse != null && analysisResponse['code'] == 200) {
          _analysis = analysisResponse['data'];
        }
        _localLogs = logsResponse;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _analysis == null
        ? const Center(child: Text('暂无运动分析数据'))
        : SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                _buildScoreCard(colorScheme),
                SizedBox(height: 20.sp),
                _buildWeeklyChart(colorScheme),
                SizedBox(height: 20.sp),
                _buildAiFeedbackCard(colorScheme),
                SizedBox(height: 30.sp),
                SizedBox(
                  width: double.infinity,
                  height: 50.sp,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _loadAnalysis(force: true),
                    icon: _isLoading
                        ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isLoading ? '分析中...' : '重新分析'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.sp),
              ],
            ),
          );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动洞察'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAnalysis(force: true),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildScoreCard(ColorScheme colorScheme) {
    int score = _analysis!['score'] ?? 0;
    String rating = score >= 90
        ? '极佳'
        : score >= 70
        ? '良好'
        : '需加油';
    Color scoreColor = score >= 80
        ? Colors.green
        : score >= 60
        ? Colors.orange
        : Colors.red;

    return Card(
      elevation: 0,
      color: scoreColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.sp),
        side: BorderSide(color: scoreColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80.sp,
                  height: 80.sp,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8.sp,
                    color: scoreColor,
                    backgroundColor: scoreColor.withOpacity(0.1),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            SizedBox(width: 20.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '近期运动表现: $rating',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    '该分数基于您过去14天的运动频率与强度综合计算得出。',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(ColorScheme colorScheme) {
    // 1. 确定日期范围（最近7天）
    DateTime now = DateTime.now();
    List<String> last7Days = List.generate(7, (i) {
      return DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: 6 - i)));
    });

    // 2. 本地聚合每日卡路里 (kcal)
    Map<String, double> dailyKcalMap = {for (var date in last7Days) date: 0.0};
    for (var log in _localLogs) {
      String date = log.trainedDate.split(" ")[0];
      if (dailyKcalMap.containsKey(date)) {
        double kcal =
            ((log.consumption == null || log.consumption == 0)
                    ? (log.trainedDuration / 60 * 6.5)
                    : log.consumption!)
                .toDouble();
        dailyKcalMap[date] = dailyKcalMap[date]! + kcal;
      }
    }

    // 3. 构建 chart spots
    List<FlSpot> spots = [];
    for (int i = 0; i < last7Days.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyKcalMap[last7Days[i]]!));
    }

    // 4. 计算 Y 轴最大值 (美化显示)
    double maxKcal = dailyKcalMap.values.fold(
      0.0,
      (max, v) => v > max ? v : max,
    );
    double maxY = (maxKcal > 100) ? (maxKcal * 1.2) : 100.0;

    return Container(
      height: 250.sp,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近一周运动消耗 (kcal)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          SizedBox(height: 20.sp),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        colorScheme.primary.withOpacity(0.9),
                    tooltipBorderRadius: BorderRadius.circular(8.sp),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} kcal',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // 确保每个点只显示一个标题，防止重叠
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= last7Days.length)
                          return const SizedBox();
                        // 显示 MM-DD 格式
                        String date = last7Days[idx].substring(5);
                        return Padding(
                          padding: EdgeInsets.only(top: 8.sp),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 4.sp,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeedbackCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: colorScheme.primary, size: 28.sp),
                SizedBox(width: 8.sp),
                Text(
                  'AI 教练反馈',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            MarkdownBody(
              data: _analysis!['feedback'] ?? '正在整理您的运动数据...',
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 14.sp,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
