import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';
import '../../core/utils/tool_widgets.dart';
import 'records/ai_suggestion/ai_suggestion_page.dart';
import 'diet_history.dart';
import 'ai_dietary_suggestions.dart';

class DietEntryPage extends StatefulWidget {
  const DietEntryPage({super.key});

  @override
  State<DietEntryPage> createState() => _DietEntryPageState();
}

class _DietEntryPageState extends State<DietEntryPage> {
  final _foodController = TextEditingController();
  final _amountController = TextEditingController();
  final _aiController = TextEditingController();
  String _selectedCategory = '主食';
  String _selectedMeal = 'breakfast';
  final _dbHelper = DBHealthHelper();
  bool _isSaving = false;
  bool _isAiParsing = false;
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
    final logs = await _dbHelper.queryDietList(date: todayStr);
    if (mounted) {
      setState(() {
        _todayLogs = logs;
        _isLoading = false;
      });
    }
  }

  final Map<String, List<double>> _nutritionMap = {
    '主食': [1.5, 0.03, 0.35, 0.01], // kcal/g, protein/g, carbs/g, fat/g
    '肉类': [2.5, 0.20, 0.01, 0.18],
    '果蔬': [0.4, 0.01, 0.08, 0.00],
    '其他': [1.0, 0.02, 0.15, 0.05],
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
      double carbs = amount * _nutritionMap[_selectedCategory]![2];
      double fat = amount * _nutritionMap[_selectedCategory]![3];

      final log = DietLog(
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        category: _selectedMeal,
        foodName: _foodController.text,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        water: _selectedCategory == '其他' && _foodController.text.contains('水')
            ? amount
            : 0,
        gmtCreate: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertDiet(log);

      if (!mounted) return;

      showSnackMessage(context, '保存成功！', backgroundColor: colorScheme.primary);
      _foodController.clear();
      _amountController.clear();
      _loadTodayLogs();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('饮食 / Diet'),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 4.sp,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: '记饮食'),
              Tab(text: '历史记录'),
              Tab(text: 'AI 建议'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: EdgeInsets.all(16.sp),
              children: [
                _buildAiInputSection(colorScheme),
                SizedBox(height: 24.sp),
                Divider(height: 32.sp, thickness: 0.5),
                _buildManualHeader(colorScheme),
                SizedBox(height: 16.sp),
                _buildDietEntryForm(colorScheme),
              ],
            ),
            const DietHistoryPage(),
            const AiDietarySuggestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8.sp),
        Text(
          '手动记录',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAiInputSection(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sp),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: colorScheme.primary, size: 24.sp),
                SizedBox(width: 8.sp),
                Text(
                  'AI 智能识别',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            TextField(
              controller: _aiController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述你吃了什么，例如：\n“中午吃了300g番茄炒鸡蛋，一碗米饭”',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: colorScheme.outline,
                ),
                fillColor: colorScheme.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.sp),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.sp),
            ElevatedButton.icon(
              onPressed: _isAiParsing ? null : _handleAiSave,
              icon: _isAiParsing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isAiParsing ? '正在识别...' : 'AI 识别并添加'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45.sp),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAiSave() async {
    final text = _aiController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAiParsing = true);

    try {
      final response = await _dbHelper.parseAiText(text);
      if (response != null &&
          response['code'] == 200 &&
          response['data'] != null) {
        final data = response['data'];
        final foodsList = data['foods'] as List;

        if (foodsList.isEmpty) {
          showSnackMessage(context, 'AI 未能识别出具体的食物，请尝试更详细的描述。');
          return;
        }

        int successCount = 0;
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final nowStr = DateTime.now().toIso8601String();

        for (var foodItem in foodsList) {
          final log = DietLog(
            date: todayStr,
            category: _selectedMeal,
            foodName: foodItem['foodName'] ?? '未知食物',
            calories: (foodItem['calories'] ?? 0.0).toDouble(),
            protein: (foodItem['protein'] ?? 0.0).toDouble(),
            fat: (foodItem['fat'] ?? 0.0).toDouble(),
            carbs: (foodItem['carbs'] ?? 0.0).toDouble(),
            water: (foodItem['water'] ?? 0.0).toDouble(),
            gmtCreate: nowStr,
          );
          await _dbHelper.insertDiet(log);
          successCount++;
        }

        showSnackMessage(
          context,
          '成功识别并添加 $successCount 项饮食记录！',
          backgroundColor: Colors.green,
        );
        _aiController.clear();
        _loadTodayLogs();
      } else {
        showSnackMessage(context, 'AI 识别失败，请稍后重试。');
      }
    } catch (e) {
      showSnackMessage(context, '请求出错: $e');
    } finally {
      setState(() => _isAiParsing = false);
    }
  }

  Widget _buildDietEntryForm(ColorScheme colorScheme) {
    return Column(
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealLabel,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 4.sp),
            Wrap(
              spacing: 8.sp,
              runSpacing: 4.sp,
              children: [
                _buildNutrientChip(
                  '蛋 ${log.protein.toStringAsFixed(1)}g',
                  Colors.orange,
                ),
                _buildNutrientChip(
                  '碳 ${log.carbs.toStringAsFixed(1)}g',
                  Colors.blue,
                ),
                _buildNutrientChip(
                  '脂 ${log.fat.toStringAsFixed(1)}g',
                  Colors.red,
                ),
                if (log.water > 0)
                  _buildNutrientChip(
                    '水 ${log.water.toStringAsFixed(0)}ml',
                    Colors.cyan,
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${log.calories.toStringAsFixed(0)} kcal',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
