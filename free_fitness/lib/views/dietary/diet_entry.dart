import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';

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

  final Map<String, List<double>> _nutritionMap = {
    '主食': [1.5, 0.03], // kcal/g, protein/g
    '肉类': [2.5, 0.20],
    '果蔬': [0.4, 0.01],
    '其他': [1.0, 0.02],
  };

  Future<void> _saveDiet() async {
    if (_foodController.text.isEmpty || _amountController.text.isEmpty) return;

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
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('添加饮食 / Add Diet')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedMeal,
              items: const [
                DropdownMenuItem(
                  value: 'breakfast',
                  child: Text('早餐 Breakfast'),
                ),
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
                '保存并分析能量',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
