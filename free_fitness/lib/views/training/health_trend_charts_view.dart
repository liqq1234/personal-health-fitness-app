import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/health_models.dart';
import '../../models/training_state.dart';
import '../../core/storage/db_training_helper.dart';
import '../../core/storage/db_sleep_helper.dart';

class HealthTrendChartsView extends StatefulWidget {
  const HealthTrendChartsView({super.key});

  @override
  State<HealthTrendChartsView> createState() => _HealthTrendChartsViewState();
}

class _HealthTrendChartsViewState extends State<HealthTrendChartsView> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();
  final DBSleepHelper _sleepHelper = DBSleepHelper();

  List<TrainedDetailLog> _trainingLogs = [];
  List<SleepRecord> _sleepRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final startDate =
        "${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}";
    final endDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final logs = await _trainingHelper.queryTrainedDetailLog(
      startDate: startDate,
      endDate: endDate,
    );
    final sleeps = await _sleepHelper.querySleepRecords(
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      _trainingLogs = logs;
      _sleepRecords = sleeps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '健康趋势',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildChartCard('训练容量趋势 (kg)', _buildTrainingVolumeChart()),
          const SizedBox(height: 20),
          _buildChartCard('睡眠时长分布 (h)', _buildSleepDurationChart()),
          const SizedBox(height: 20),
          _buildFeedbackSummary(),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildTrainingVolumeChart() {
    if (_trainingLogs.isEmpty) return const Center(child: Text("暂无训练数据"));

    // Process logs into daily totals
    Map<String, double> dailyVolume = {};
    for (var log in _trainingLogs) {
      String date = log.trainedDate.split(' ')[0];
      double volume = (log.reps ?? 0) * (log.weights ?? 0);
      dailyVolume[date] = (dailyVolume[date] ?? 0) + volume;
    }

    final List<BarChartGroupData> barGroups = [];
    int i = 0;
    dailyVolume.forEach((date, volume) {
      barGroups.add(
        BarChartGroupData(
          x: i++,
          barRods: [
            BarChartRodData(
              toY: volume,
              color: Colors.blueAccent,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
      ),
    );
  }

  Widget _buildSleepDurationChart() {
    if (_sleepRecords.isEmpty) return const Center(child: Text("暂无睡眠数据"));

    final List<FlSpot> spots = [];
    for (int i = 0; i < _sleepRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), _sleepRecords[i].durationHours));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purpleAccent,
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purpleAccent.withOpacity(0.1),
            ),
          ),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
      ),
    );
  }

  Widget _buildFeedbackSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                '智能反馈',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _trainingLogs.isEmpty
                ? '开始你的第一次训练，获取 AI 深度分析反馈。'
                : '本周总训练容量已达 ${(_trainingLogs.fold(0.0, (sum, item) => sum + (item.reps ?? 0) * (item.weights ?? 0)) / 1000).toStringAsFixed(1)} 吨。继续保持，建议下周适当增加深蹲组数以突破平台期。',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
