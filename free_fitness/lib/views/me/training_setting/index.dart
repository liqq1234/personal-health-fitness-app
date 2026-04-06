import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../core/storage/db_user_helper.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';

class TrainingSetting extends StatefulWidget {
  final User userInfo;

  const TrainingSetting({super.key, required this.userInfo});

  @override
  State<TrainingSetting> createState() => _TrainingSettingState();
}

class _TrainingSettingState extends State<TrainingSetting> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 当前的休息间隔时间
  int _currentNumber = 10;

  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.userInfo;
    _currentNumber = user.actionRestTime ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CusAL.of(context).settingLabels('3'))),
      body: ListView(
        children: [
          _buildListItem(
            CusAL.of(context).restIntervals,
            "${user.actionRestTime ?? 10}",
            () => _openActionRestTimeDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String title, dynamic value, VoidCallback onTap) {
    return Card(
      elevation: 2.sp,
      child: ListTile(
        title: Text(title),
        subtitle: Text(value.toString()),
        onTap: onTap,
      ),
    );
  }

  Future _openActionRestTimeDialog() async {
    // 每次打开弹窗前，先同步一下最新的休息间隔时间，避免之前操作的影响
    _currentNumber = user.actionRestTime ?? 10;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            CusAL.of(context).chooseSeconds,
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 150.sp,
                child: NumberPicker(
                  itemCount: 3,
                  minValue: 5,
                  maxValue: 60,
                  value: _currentNumber,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.sp),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  onChanged: (value) {
                    setState(() => _currentNumber = value);
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(CusAL.of(context).cancelLabel),
            ),
            TextButton(
              onPressed: () async {
                if (user.userId == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("用户ID为空，无法更新")));
                  return;
                }

                // 先更新本地对象的值再请求
                user.actionRestTime = _currentNumber;
                int success = await _userHelper.updateUser(user);

                if (success == 1) {
                  setState(() {
                    // 这里触发 UI 刷新即可
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("更新成功")));
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("更新失败，请重试")));
                  }
                }

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
