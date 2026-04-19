import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/storage/db_health_helper.dart';

class SleepInsightsPage extends StatefulWidget {
  final bool showAppBar;
  const SleepInsightsPage({super.key, this.showAppBar = true});

  @override
  State<SleepInsightsPage> createState() => _SleepInsightsPageState();
}

class _SleepInsightsPageState extends State<SleepInsightsPage> {
  Map<String, dynamic>? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis(force: false);
  }

  Future<void> _loadAnalysis({bool force = false}) async {
    setState(() => _isLoading = true);
    final response = await DBHealthHelper().getSleepAnalysis(force: force);
    if (mounted) {
      setState(() {
        if (response != null && response['code'] == 200) {
          _analysis = response['data'];
        }
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
        ? const Center(child: Text('暂无睡眠分析数据'))
        : SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                _buildScoreCard(colorScheme),
                SizedBox(height: 20.sp),
                _buildWeeklyDurationChart(colorScheme),
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
                    label: Text(_isLoading ? '分析中...' : '重新分析睡眠'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
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
        title: const Text('睡眠洞察'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildScoreCard(ColorScheme colorScheme) {
    int score = _analysis!['score'] ?? 0;
    String rating = score >= 85
        ? '极佳'
        : score >= 70
        ? '良好'
        : '需关注';
    Color scoreColor = score >= 80
        ? Colors.indigo
        : score >= 60
        ? Colors.blue
        : Colors.orange;

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
                    '睡眠评分: $rating',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    '该分数基于最近两周的时长、规律性与质量综合生成。',
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

  Widget _buildWeeklyDurationChart(ColorScheme colorScheme) {
    List<dynamic> weeklyData = _analysis!['weeklyData'] ?? [];
    List<BarChartGroupData> barGroups = [];

    // 计算最大时长，用于动态设置Y轴范围
    double maxDuration = 0;
    for (final entry in weeklyData) {
      double duration = (entry['duration'] as num).toDouble();
      if (duration > maxDuration) {
        maxDuration = duration;
      }
    }

    // 设置maxY为最大值向上取整，并加1小时作为余量，但最小为8小时
    double maxY = (maxDuration.ceilToDouble()).clamp(8, double.infinity);
    if (maxY - maxDuration < 1.0) {
      maxY += 1.0; // 确保有至少1小时的余量
    }

    for (int i = 0; i < weeklyData.length; i++) {
      double duration = (weeklyData[i]['duration'] as num).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: duration,
              color: Colors.indigo.shade300,
              width: 16.sp,
              borderRadius: BorderRadius.circular(4.sp),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: Colors.indigo.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }

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
            '最近一周睡眠时长 (小时)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 20.sp),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Colors.indigo.shade400.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} 小时',
                        const TextStyle(
                          color: Colors.white,
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
                      interval: 1, // 防止标签重叠
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= weeklyData.length)
                          return const SizedBox();
                        String date = weeklyData[idx]['date']
                            .toString()
                            .substring(5);
                        return Text(
                          date,
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    ),
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
                barGroups: barGroups,
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
      color: Colors.indigo.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.indigo, size: 28.sp),
                SizedBox(width: 8.sp),
                Text(
                  'AI 睡眠建议',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            MarkdownBody(
              data: _analysis!['feedback'] ?? '正在整理您的睡眠趋势...',
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
