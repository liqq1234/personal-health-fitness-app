import 'package:flutter/material.dart';
import '../../models/dietary_state.dart';
import '../../core/storage/db_dietary_helper.dart';

class NutritionAnalysisView extends StatefulWidget {
  final String date;
  const NutritionAnalysisView({super.key, required this.date});

  @override
  State<NutritionAnalysisView> createState() => _NutritionAnalysisViewState();
}

class _NutritionAnalysisViewState extends State<NutritionAnalysisView> {
  final DBDietaryHelper _dbHelper = DBDietaryHelper();
  bool _isLoading = true;
  NutritionAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final result = await _dbHelper.getAnalysis(widget.date);
    setState(() {
      _analysis = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_analysis == null)
      return const Scaffold(body: Center(child: Text("加载分析失败")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '营养分析 - ${widget.date}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 25),
            const Text(
              '营养指标明细',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildMetricGrid(),
            const SizedBox(height: 30),
            const Text(
              '专家建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ..._analysis!.recommendations.map(
              (r) => _buildRecommendationCard(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.8),
            Colors.blue.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '每日总结',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _analysis!.statusSummary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_analysis!.currentCalories.toInt()} / ${_analysis!.targetCalories.toInt()} kcal',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    return Column(
      children: [
        _buildMetricLine(
          '蛋白质',
          _analysis!.currentProtein,
          _analysis!.targetProtein,
          'g',
          Colors.orange,
        ),
        const SizedBox(height: 15),
        _buildMetricLine(
          '脂肪',
          _analysis!.currentFat,
          _analysis!.targetFat,
          'g',
          Colors.purple,
        ),
        const SizedBox(height: 15),
        _buildMetricLine(
          '碳水',
          _analysis!.currentCarbs,
          _analysis!.targetCarbs,
          'g',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMetricLine(
    String label,
    double current,
    double target,
    String unit,
    Color color,
  ) {
    double progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${current.toInt()} / ${target.toInt()} $unit',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
