import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';

class SleepEntryPage extends StatefulWidget {
  const SleepEntryPage({super.key});

  @override
  State<SleepEntryPage> createState() => _SleepEntryPageState();
}

class _SleepEntryPageState extends State<SleepEntryPage> {
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _endTime = DateTime.now();
  final _noteController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _dbHelper = DBHealthHelper();
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _startController.text = DateFormat('yyyy-MM-dd HH:mm').format(_startTime);
    _endController.text = DateFormat('yyyy-MM-dd HH:mm').format(_endTime);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _startController.text = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(_startTime);
          } else {
            _endTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            _endController.text = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(_endTime);
          }
        });
      }
    }
  }

  Color _getSleepDurationColor() {
    double duration = _endTime.difference(_startTime).inMinutes / 60.0;
    const double minSleepHours = 0.25; // 最少15分钟
    const double maxSleepHours = 24.0; // 最多24小时

    if (duration < minSleepHours || duration > maxSleepHours) {
      return Colors.orange; // 警告色
    }
    return Colors.blue; // 正常色
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;
    double duration = _endTime.difference(_startTime).inMinutes / 60.0;
    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间')));
      return;
    }

    // 检查睡眠时长是否在合理范围内
    const double minSleepHours = 0.25; // 最少15分钟
    const double maxSleepHours = 24.0; // 最多24小时
    if (duration < minSleepHours) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('睡眠时长太短，请至少记录15分钟（0.25小时）')));
      return;
    }
    if (duration > maxSleepHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('睡眠时长过长，请检查时间设置（最长不超过24小时）')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final record = SleepRecord(
        startTime: _startTime.toIso8601String(),
        endTime: _endTime.toIso8601String(),
        durationHours: duration,
        note: _noteController.text,
        gmtCreate: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertSleep(record);
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录睡眠 / Sleep Record')),
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _selectDateTime(context, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '入睡时间 *',
                      prefixIcon: const Icon(Icons.bedtime),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorStyle: TextStyle(fontSize: 12.sp),
                    ),
                    controller: _startController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择入睡时间';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.sp),
              GestureDetector(
                onTap: () => _selectDateTime(context, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '醒来时间 *',
                      prefixIcon: const Icon(Icons.wb_sunny),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorStyle: TextStyle(fontSize: 12.sp),
                    ),
                    controller: _endController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择醒来时间';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.sp),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.sp,
                    vertical: 10.sp,
                  ),
                  decoration: BoxDecoration(
                    color: _getSleepDurationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.sp),
                    border: Border.all(
                      color: _getSleepDurationColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '睡眠时长: ${(_endTime.difference(_startTime).inMinutes / 60.0).toStringAsFixed(1)} 小时',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _getSleepDurationColor(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.sp),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注/心情',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.sp),
                ),
                onPressed: _isSaving ? null : _saveRecord,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('保存记录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
