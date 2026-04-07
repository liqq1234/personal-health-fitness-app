import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';
import '../dietary/records/ai_suggestion/ai_suggestion_page.dart';
import '../../core/utils/tool_widgets.dart';
import 'diet_history.dart';

class DietEntryPage extends StatefulWidget {
  const DietEntryPage({super.key});

  @override
  State<DietEntryPage> createState() => _DietEntryPageState();
}

class _DietEntryPageState extends State<DietEntryPage> {
  final _foodController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = '主食';
  String _selectedMeal = 'breakfast';
  final _dbHelper = DBHealthHelper();
  bool _isSaving = false;
  List<DietLog> _todayLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayLogs();
  }

  Future<void> _loadTodayLogs() async {
    setState(() => _isLoading = true);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logs = await _dbHelper.queryDietList(
      startDate: todayStr,
      endDate: todayStr,
    );
    if (mounted) {
      setState(() {
        _todayLogs = logs;
        _isLoading = false;
      });
    }
  }

  final Map<String, List<double>> _nutritionMap = {
    '主食': [1.5, 0.03], // kcal/g, protein/g
    '肉类': [2.5, 0.20],
    '果蔬': [0.4, 0.01],
    '其他': [1.0, 0.02],
  };

  Future<void> _saveDiet() async {
    if (_isSaving) return;
    if (_foodController.text.isEmpty || _amountController.text.isEmpty) return;

    setState(() => _isSaving = true);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      double amount = double.tryParse(_amountController.text) ?? 0;
      double calories = amount * _nutritionMap[_selectedCategory]![0];
      double protein = amount * _nutritionMap[_selectedCategory]![1];

      final log = DietLog(
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        category: _selectedMeal,
        foodName: _foodController.text,
        calories: calories,
        protein: protein,
        gmtCreate: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertDiet(log);

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // 底部 Tab 模式
        showSnackMessage(
          context,
          '保存成功！',
          backgroundColor: colorScheme.primary,
        );
        _foodController.clear();
        _amountController.clear();
        _loadTodayLogs();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('饮食 / Diet'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '记饮食'),
              Tab(text: '饮食记录'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 第一页：添加饮食表单及今日列表
            _buildDietEntryForm(colorScheme),
            // 第二页：历史记录列表
            const DietHistoryPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildDietEntryForm(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedMeal,
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('早餐 Breakfast')),
              DropdownMenuItem(value: 'lunch', child: Text('午餐 Lunch')),
              DropdownMenuItem(value: 'dinner', child: Text('晚餐 Dinner')),
              DropdownMenuItem(value: 'snack', child: Text('零食/加餐 Snack')),
            ],
            onChanged: (v) => setState(() => _selectedMeal = v!),
            decoration: const InputDecoration(
              labelText: '餐次',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.sp),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _nutritionMap.keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration: const InputDecoration(
              labelText: '食物种类',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.sp),
          TextField(
            controller: _foodController,
            decoration: const InputDecoration(
              labelText: '食物名称 (如: 米饭)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.sp),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '摄入量 (克/g)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 12.sp),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                String food = _foodController.text;
                String amount = _amountController.text;
                String prompt = "";
                if (food.isNotEmpty || amount.isNotEmpty) {
                  prompt =
                      "我想知道：食物名称【$food】，摄入量【$amount 克/g】。请帮我分析它的卡路里/能量以及主要营养成分。";
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OneChatScreen(intakeInfo: prompt),
                  ),
                );
              },
              icon: const Icon(Icons.psychology, size: 20),
              label: const Text('问问 AI 助手 (分析热量)'),
            ),
          ),
          SizedBox(height: 32.sp),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50.sp),
              elevation: 0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.sp),
              ),
            ),
            onPressed: _saveDiet,
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 32.sp),
          _buildTodayRecordsList(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTodayRecordsList(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_todayLogs.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20.sp),
        child: Text(
          '今日暂无饮食记录',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 20.sp, color: colorScheme.primary),
            SizedBox(width: 8.sp),
            Text(
              '今日记录',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        ...(_todayLogs
            .map((log) => _buildRecordItem(log, colorScheme))
            .toList()),
      ],
    );
  }

  Widget _buildRecordItem(DietLog log, ColorScheme colorScheme) {
    String mealLabel = "";
    IconData mealIcon;
    switch (log.category) {
      case 'breakfast':
        mealLabel = "早餐";
        mealIcon = Icons.wb_sunny_outlined;
        break;
      case 'lunch':
        mealLabel = "午餐";
        mealIcon = Icons.wb_cloudy_outlined;
        break;
      case 'dinner':
        mealLabel = "晚餐";
        mealIcon = Icons.nightlight_outlined;
        break;
      default:
        mealLabel = "加餐";
        mealIcon = Icons.restaurant_menu;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.sp),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            mealIcon,
            color: colorScheme.onSecondaryContainer,
            size: 20.sp,
          ),
        ),
        title: Text(
          log.foodName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
        ),
        subtitle: Text(
          mealLabel,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13.sp,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${log.calories.toStringAsFixed(0)} kcal',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            Text(
              '蛋白质 ${log.protein.toStringAsFixed(1)}g',
              style: TextStyle(color: Colors.orange, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }
}
