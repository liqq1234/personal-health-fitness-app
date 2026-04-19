import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/tools.dart';
import '../../models/training_state.dart';
import '../../services/notification_service.dart';
import '../../services/training_schedule_service.dart';
import '../../core/storage/db_training_helper.dart';
import 'workouts/action_follow_practice.dart';

class ScheduleTrainingPage extends StatefulWidget {
  const ScheduleTrainingPage({super.key});

  @override
  State<ScheduleTrainingPage> createState() => _ScheduleTrainingPageState();
}

class _ScheduleTrainingPageState extends State<ScheduleTrainingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TrainingSchedule>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final list = await TrainingScheduleService.getAllSchedules(
        CacheUser.userId,
      );
      final Map<DateTime, List<TrainingSchedule>> eventSource = {};
      for (var s in list) {
        final date = DateTime.parse(s.scheduledDate);
        final dateKey = DateTime.utc(date.year, date.month, date.day);
        if (eventSource[dateKey] == null) eventSource[dateKey] = [];
        eventSource[dateKey]!.add(s);
      }
      setState(() {
        _events = eventSource;
      });
    } catch (e) {
      debugPrint('加载排程失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final List<Map<String, dynamic>> _activityOptions = [
    {'name': '跑步', 'icon': Icons.directions_run},
    {'name': '步行', 'icon': Icons.directions_walk},
    {'name': '骑行', 'icon': Icons.directions_bike},
    {'name': '游泳', 'icon': Icons.pool},
    {'name': '力量训练', 'icon': Icons.fitness_center},
    {'name': '瑜伽', 'icon': Icons.self_improvement},
    {'name': '其他', 'icon': Icons.more_horiz},
  ];

  List<TrainingSchedule> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练计划')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(child: _buildScheduleList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildScheduleList() {
    final dayEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    if (dayEvents.isEmpty) {
      return const Center(child: Text('当日暂无训练计划'));
    }
    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final schedule = dayEvents[index];
        final activity = _activityOptions.firstWhere(
          (element) => element['name'] == schedule.trainingName,
          orElse: () => {'icon': Icons.event},
        );

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: ListTile(
            leading: Icon(
              activity['icon'] as IconData,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              schedule.trainingName ?? '未命名活动',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '预计: ${schedule.startTime.substring(0, 5)} | 时长: ${() {
                try {
                  final start = DateFormat('HH:mm:ss').parse(schedule.startTime);
                  final end = DateFormat('HH:mm:ss').parse(schedule.endTime);
                  return end.difference(start).inMinutes;
                } catch (e) {
                  return 0;
                }
              }()} 分钟 | ${schedule.totalSets ?? 1} 组',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (schedule.status == 'COMPLETED')
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _completeSchedule(schedule),
                    tooltip: '标记为完成',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSchedule(schedule),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddScheduleDialog() async {
    String? selectedActivity = _activityOptions[0]['name'];
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    int totalDurationMin = 60;
    int remindMin = 15;
    int sets = 1;
    int restSec = 30;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加训练排程'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择训练内容',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10.sp),
                    Wrap(
                      spacing: 8.sp,
                      runSpacing: 4.sp,
                      children: _activityOptions.map((opt) {
                        final bool isSelected = selectedActivity == opt['name'];
                        return ChoiceChip(
                          label: Text(opt['name']),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              setDialogState(
                                () => selectedActivity = opt['name'],
                              );
                            }
                          },
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开始时间'),
                      trailing: Text(startTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null)
                          setDialogState(() => startTime = picked);
                      },
                    ),
                    const Divider(),
                    const Text('训练总时间 (分钟)'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: totalDurationMin.toDouble(),
                            min: 5,
                            max: 180,
                            divisions: 35,
                            label: '$totalDurationMin',
                            onChanged: (val) => setDialogState(
                              () => totalDurationMin = val.toInt(),
                            ),
                          ),
                        ),
                        Text('$totalDurationMin m'),
                      ],
                    ),
                    const Divider(),
                    const Text('提醒时间(分钟)'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: remindMin.toDouble(),
                            min: 0,
                            max: 60,
                            divisions: 12,
                            label: '$remindMin',
                            onChanged: (val) =>
                                setDialogState(() => remindMin = val.toInt()),
                          ),
                        ),
                        Text('$remindMin'),
                      ],
                    ),
                    const Divider(),
                    const Text('组数 & 休息'),
                    Row(
                      children: [
                        const Text('组数:'),
                        Expanded(
                          child: Slider(
                            value: sets.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '$sets',
                            onChanged: (val) =>
                                setDialogState(() => sets = val.toInt()),
                          ),
                        ),
                        Text('$sets'),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('休息:'),
                        Expanded(
                          child: Slider(
                            value: restSec.toDouble(),
                            min: 0,
                            max: 300,
                            divisions: 30,
                            label: '${restSec}s',
                            onChanged: (val) =>
                                setDialogState(() => restSec = val.toInt()),
                          ),
                        ),
                        Text('${restSec}s'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedActivity == null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('请选择训练内容')));
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    ).then((confirmed) {
      if (confirmed == true && selectedActivity != null) {
        _saveSchedule(
          selectedActivity!,
          startTime,
          totalDurationMin,
          remindMin,
          sets,
          restSec,
        );
      }
    });
  }

  Future<void> _saveSchedule(
    String activityName,
    TimeOfDay start,
    int durationMin,
    int remindMin,
    int sets,
    int restSec,
  ) async {
    final String dateStr = formatDateToString(_selectedDay ?? _focusedDay);

    // 计算结束时间
    final startDateTime = DateTime(2000, 1, 1, start.hour, start.minute);
    final endDateTime = startDateTime.add(Duration(minutes: durationMin));
    final end = TimeOfDay.fromDateTime(endDateTime);

    final schedule = TrainingSchedule(
      userId: CacheUser.userId,
      trainingType: 'ACTIVITY',
      trainingName: activityName,
      targetId: 0,
      scheduledDate: dateStr,
      startTime:
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
      endTime:
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
      remindBeforeMinutes: remindMin,
      totalSets: sets,
      restDuration: restSec,
      sportType: activityName,
    );

    final saved = await TrainingScheduleService.createSchedule(schedule);
    if (saved != null) {
      if (remindMin > 0) {
        final scheduledTime = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
          start.hour,
          start.minute,
        ).subtract(Duration(minutes: remindMin));

        if (scheduledTime.isAfter(DateTime.now())) {
          try {
            await NotificationService().scheduleNotification(
              id: saved.scheduleId!,
              title: '训练计划提醒',
              body: '您预约的 [$activityName] 即将开始，请做好准备！',
              scheduledDate: scheduledTime,
            );
          } catch (e) {
            debugPrint('分发通知提醒报错: $e');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('计划已成功保存'), backgroundColor: Colors.green),
      );
      _loadSchedules();
    }
  }

  Future<void> _deleteSchedule(TrainingSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('您确定要删除此训练排程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && schedule.scheduleId != null) {
      final success = await TrainingScheduleService.deleteSchedule(
        schedule.scheduleId!,
      );
      if (success) {
        await NotificationService().cancelNotification(schedule.scheduleId!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('排程已删除')));
        _loadSchedules();
      }
    }
  }

  Future<void> _completeSchedule(TrainingSchedule schedule) async {
    // 检查如果是 ACTIVITY 类型，进入计时器模式
    if (schedule.trainingType == 'ACTIVITY') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('开始 [${schedule.trainingName}]'),
          content: Text(
            '将开始实时计时追踪。设定: ${schedule.totalSets ?? 1} 组，组间休息 ${schedule.restDuration ?? 0}s。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('以后再说'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('立即开始'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // 构建 ActionDetail 列表
        // 尝试从本地或云端获取 Exercise 信息，如果没有，构建一个临时的
        CusDataResult exercises = await DBTrainingHelper()
            .queryExerciseByKeyword(
              keyword: schedule.trainingName!,
              pageSize: 1,
              page: 1,
            );

        Exercise? exercise;
        if (exercises.data.isNotEmpty) {
          exercise = exercises.data.first as Exercise;
        } else {
          // 兜底：构建一个简单的 Exercise 对象
          exercise = Exercise(
            exerciseCode: 'TEMP_CODE',
            exerciseName: schedule.trainingName!,
            countingMode: countingOptions.first.value, // 计时模式
            standardDuration: 1,
            category: '健身',
          );
        }

        // 计算每组时长
        int setsCount = schedule.totalSets ?? 1;
        int durationPerSet = 60;
        try {
          final start = DateFormat('HH:mm:ss').parse(schedule.startTime);
          final end = DateFormat('HH:mm:ss').parse(schedule.endTime);
          durationPerSet = (end.difference(start).inSeconds) ~/ setsCount;
        } catch (e) {
          debugPrint('计算每组时长失败: $e');
        }

        // 创建 ActionDetail 列表（重复 sets 次）
        List<ActionDetail> actionList = [];
        for (int i = 0; i < setsCount; i++) {
          actionList.add(
            ActionDetail(
              exercise: exercise,
              action: TrainingAction(
                groupId: 0,
                exerciseId: exercise.exerciseId ?? 0,
                duration: durationPerSet,
              ),
            ),
          );
        }

        // 导航到计时器页面
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActionFollowPracticeWithTTS(
              actionList: actionList,
              group: TrainingGroup(
                groupName: schedule.trainingName!,
                groupCategory: 'Scheduled Activity',
                groupLevel: 'Normal',
              ),
              // 这里传训练内容的名称作为 planName
              plan: TrainingPlan(
                planCode: 'SCHED',
                planName: schedule.trainingName!,
                planCategory: 'General',
                planLevel: 'Normal',
                planPeriod: 1,
                sportType: schedule.sportType,
              ),
              // dayNumber 传 null，表示这是一个单次排程，不是周期计划中的某一天
              dayNumber: null,
            ),
          ),
        ).then((_) {
          // 结束后刷新列表
          _loadSchedules();
        });
        return;
      }
      return;
    }

    // 原有的 PLAN/GROUP 完成逻辑
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认完成'),
        content: Text('您确定已完成 [${schedule.trainingName}] 训练吗？完成后将生成一笔运动记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 1. 计算时长 (秒)
        final startParts = schedule.startTime.split(':');
        final endParts = schedule.endTime.split(':');
        final startSecs =
            int.parse(startParts[0]) * 3600 +
            int.parse(startParts[1]) * 60 +
            int.parse(startParts[2]);
        final endSecs =
            int.parse(endParts[0]) * 3600 +
            int.parse(endParts[1]) * 60 +
            int.parse(endParts[2]);
        int duration = endSecs - startSecs;
        if (duration < 0) duration = 0;

        // 2. 更新排程状态
        final updated = schedule.copyWith(status: 'COMPLETED');
        await TrainingScheduleService.updateSchedule(
          schedule.scheduleId!,
          updated,
        );

        // 3. 生成训练日志
        // 确保 scheduledDate 只包含日期部分（YYYY-MM-DD 格式）
        String formattedDate = schedule.scheduledDate;
        if (schedule.scheduledDate.contains(' ')) {
          formattedDate = schedule.scheduledDate.split(' ')[0];
        } else if (schedule.scheduledDate.length > 10) {
          formattedDate = schedule.scheduledDate.substring(0, 10);
        }

        final log = TrainedDetailLog(
          trainedDate: formattedDate,
          userId: CacheUser.userId,
          // 根据 type 填充
          planName: schedule.trainingType == 'PLAN'
              ? schedule.trainingName
              : null,
          groupName: schedule.trainingType == 'GROUP'
              ? schedule.trainingName
              : schedule.trainingName,
          trainedStartTime: '$formattedDate ${schedule.startTime}',
          trainedEndTime: '$formattedDate ${schedule.endTime}',
          trainedDuration: duration,
          totolPausedTime: 0,
          totalRestTime: 0,
          consumption: (duration / 60 * 5).toInt(), // 粗略估算 5kcal/min
        );

        await DBTrainingHelper().insertTrainedDetailLog(log);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已标记为完成，记录已生成'),
            backgroundColor: Colors.green,
          ),
        );

        _loadSchedules();
      } catch (e) {
        debugPrint('标记完成失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
