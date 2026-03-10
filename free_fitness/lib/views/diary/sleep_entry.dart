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
  final _dbHelper = DBHealthHelper();

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
          } else {
            _endTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          }
        });
      }
    }
  }

  Future<void> _saveRecord() async {
    double duration = _endTime.difference(_startTime).inMinutes / 60.0;
    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间')));
      return;
    }

    final record = SleepRecord(
      startTime: _startTime.toIso8601String(),
      endTime: _endTime.toIso8601String(),
      durationHours: duration,
      note: _noteController.text,
      gmtCreate: DateTime.now().toIso8601String(),
    );

    await _dbHelper.insertSleep(record);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录睡眠 / Sleep Record')),
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _selectDateTime(context, true),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '入睡时间',
                    prefixIcon: Icon(Icons.bedtime),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd HH:mm').format(_startTime),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            GestureDetector(
              onTap: () => _selectDateTime(context, false),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '醒来时间',
                    prefixIcon: Icon(Icons.wb_sunny),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd HH:mm').format(_endTime),
                  ),
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.sp),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  '睡眠时长: ${(_endTime.difference(_startTime).inMinutes / 60.0).toStringAsFixed(1)} 小时',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
              onPressed: _saveRecord,
              child: const Text('保存记录'),
            ),
          ],
        ),
      ),
    );
  }
}
