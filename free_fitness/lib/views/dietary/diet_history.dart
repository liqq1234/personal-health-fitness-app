import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';

class DietHistoryPage extends StatefulWidget {
  const DietHistoryPage({super.key});

  @override
  State<DietHistoryPage> createState() => _DietHistoryPageState();
}

class _DietHistoryPageState extends State<DietHistoryPage> {
  final _dbHelper = DBHealthHelper();
  DateTime _selectedDate = DateTime.now();
  List<DietLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final logs = await _dbHelper.queryDietList(
      startDate: dateStr,
      endDate: dateStr,
    );
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  double get _totalCalories => _logs.fold(0, (sum, e) => sum + e.calories);
  double get _totalProtein => _logs.fold(0, (sum, e) => sum + e.protein);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildHeader(colorScheme),
        _buildSummaryCard(colorScheme),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
              ? Center(
                  child: Text(
                    '当日无饮食记录',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.sp),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return _buildRecordItem(_logs[index], colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('yyyy年MM月dd日').format(_selectedDate),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.sp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '总热量',
            '${_totalCalories.toStringAsFixed(0)}',
            'kcal',
            colorScheme,
          ),
          _buildSummaryItem(
            '总蛋白质',
            '${_totalProtein.toStringAsFixed(1)}',
            'g',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    String unit,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 4.sp),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
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
}
