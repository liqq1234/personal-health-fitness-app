import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../core/constants/constants.dart';
import '../../../core/storage/db_user_helper.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../core/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';
import 'weight_change_line_chart.dart';
import 'weight_record_manage.dart';

class WeightChangeRecord extends StatefulWidget {
  final User userInfo;

  const WeightChangeRecord({super.key, required this.userInfo});

  @override
  State<WeightChangeRecord> createState() => _WeightChangeRecordState();
}

class _WeightChangeRecordState extends State<WeightChangeRecord> {
  final DBUserHelper _userHelper = DBUserHelper();

  double _currentWeight = 0;
  double _currentHeight = 0;

  // 使用 ValueNotifier 隔离关键状态
  final ValueNotifier<User> _userNotifier = ValueNotifier<User>(
    User(userName: ""),
  );
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Key> _chartKeyNotifier = ValueNotifier<Key>(UniqueKey());

  @override
  void initState() {
    super.initState();
    _userNotifier.value = widget.userInfo;
    _currentWeight = widget.userInfo.currentWeight ?? 70;
    _currentHeight = widget.userInfo.height ?? 170;
  }

  @override
  void dispose() {
    _userNotifier.dispose();
    _loadingNotifier.dispose();
    _chartKeyNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshUser() async {
    if (_loadingNotifier.value) return;
    _loadingNotifier.value = true;

    try {
      var tempUser = await _userHelper.queryUser(userId: CacheUser.userId);
      if (tempUser != null && mounted) {
        _userNotifier.value = tempUser;
        _currentWeight = tempUser.currentWeight ?? 70;
        _currentHeight = tempUser.height ?? 170;
        _chartKeyNotifier.value = UniqueKey();
      }
    } finally {
      if (mounted) _loadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CusAL.of(context).settingLabels('1'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(5.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...buildWeghtLineArea(),
              ...buildBmiArea(),
              SizedBox(height: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildWeghtLineArea() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            CusAL.of(context).weightLabel(''),
            style: TextStyle(
              fontSize: CusFontSizes.flagMedium,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WeightRecordManage(user: _userNotifier.value),
                    ),
                  ).then((value) => _refreshUser());
                },
                child: Text(CusAL.of(context).manageLabel),
              ),
              SizedBox(width: 10.sp),
              ElevatedButton(
                onPressed: () {
                  _buildModifyWeightOrBmiDialog(
                    onlyWeight: true,
                  ).then((value) => _refreshUser());
                },
                child: Text(CusAL.of(context).recordLabel),
              ),
            ],
          ),
        ],
      ),
      ValueListenableBuilder<bool>(
        valueListenable: _loadingNotifier,
        builder: (context, isLoading, _) {
          if (isLoading) return buildLoader(true);
          return ValueListenableBuilder<Key>(
            valueListenable: _chartKeyNotifier,
            builder: (context, chartKey, _) {
              return WeightChangeLineChart(
                key: chartKey,
                user: _userNotifier.value,
              );
            },
          );
        },
      ),
    ];
  }

  List<Widget> buildBmiArea() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "BMI",
                  style: TextStyle(
                    fontSize: CusFontSizes.flagMedium,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const TextSpan(
                  text: " (15 ~ 40)",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _buildModifyWeightOrBmiDialog(
                onlyWeight: false,
              ).then((value) => _refreshUser());
            },
            child: Text(CusAL.of(context).recordLabel),
          ),
        ],
      ),
      ValueListenableBuilder<User>(
        valueListenable: _userNotifier,
        builder: (context, user, _) {
          return Center(child: _buildBmiRangeContainer(context, user));
        },
      ),
    ];
  }

  SizedBox _buildBmiRangeContainer(BuildContext context, User user) {
    var tempWeight = user.currentWeight ?? 0;
    var tempHeight = (user.height ?? 0) / 100;
    var bmi = (tempHeight == 0)
        ? 0.0
        : (tempWeight / (tempHeight * tempHeight));

    var uwtFlex = ((18.4 - 15) / (40 - 15) * 300).toInt();
    var nwtFlex = ((23.9 - 18.4) / (40 - 15) * 300).toInt();
    var owtFlex = ((28 - 23.9) / (40 - 15) * 300).toInt();
    var fatFlex = ((35 - 28) / (40 - 15) * 300).toInt();
    var obesityFlex = ((40 - 35) / (40 - 15) * 300).toInt();

    return SizedBox(
      width: 320.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bmi.toStringAsFixed(2),
                style: TextStyle(fontSize: CusFontSizes.flagMedium),
              ),
              buildWeightBmiText(bmi, context),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: bmi < 15
                  ? 0
                  : bmi > 40
                  ? 300.sp
                  : ((bmi - 15) / (40 - 15) * 300.sp),
            ),
            child: Icon(Icons.arrow_downward, size: CusIconSizes.iconNormal),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: SizedBox(
              height: 30.sp,
              width: 300.sp,
              child: Row(
                children: [
                  Expanded(
                    flex: uwtFlex,
                    child: Container(
                      color: Colors.grey,
                      child: const Text("<18.4", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: nwtFlex,
                    child: Container(
                      color: Colors.green,
                      child: const Text("<23.9", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: owtFlex,
                    child: Container(
                      color: Colors.blue,
                      child: const Text("<28", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: fatFlex,
                    child: Container(
                      color: Colors.yellow,
                      child: const Text("<35", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: obesityFlex,
                    child: Container(
                      color: Colors.red,
                      child: const Text("<40", textAlign: TextAlign.end),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: SizedBox(
              height: 30.sp,
              width: 300.sp,
              child: Row(
                children: [
                  Expanded(
                    flex: uwtFlex,
                    child: Text(CusAL.of(context).bmiLabels('0')),
                  ),
                  Expanded(
                    flex: nwtFlex,
                    child: Text(CusAL.of(context).bmiLabels('1')),
                  ),
                  Expanded(
                    flex: owtFlex,
                    child: Text(CusAL.of(context).bmiLabels('2')),
                  ),
                  Expanded(
                    flex: fatFlex,
                    child: Text(CusAL.of(context).bmiLabels('3')),
                  ),
                  Expanded(
                    flex: obesityFlex,
                    child: Text(CusAL.of(context).bmiLabels('4')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _buildModifyWeightOrBmiDialog({bool onlyWeight = true}) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              height: (onlyWeight ? 220.sp : 380.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Card(
                    child: Column(
                      children: [
                        Text(
                          CusAL.of(context).weightLabel('(kg)'),
                          style: TextStyle(fontSize: CusFontSizes.flagMedium),
                        ),
                        DecimalNumberPicker(
                          value: _currentWeight,
                          minValue: 5,
                          maxValue: 300,
                          decimalPlaces: 1,
                          itemHeight: 40,
                          onChanged: (value) =>
                              setDialogState(() => _currentWeight = value),
                        ),
                      ],
                    ),
                  ),
                  if (!onlyWeight)
                    Card(
                      child: Column(
                        children: [
                          Text(
                            CusAL.of(context).heightLabel('(cm)'),
                            style: TextStyle(fontSize: CusFontSizes.flagMedium),
                          ),
                          DecimalNumberPicker(
                            value: _currentHeight,
                            minValue: 30,
                            maxValue: 240,
                            decimalPlaces: 1,
                            itemHeight: 40,
                            onChanged: (value) =>
                                setDialogState(() => _currentHeight = value),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      var user = _userNotifier.value;
                      user.height = _currentHeight;
                      user.currentWeight = _currentWeight;
                      await _userHelper.updateUser(user);
                      var bmi =
                          _currentWeight /
                          (_currentHeight / 100 * _currentHeight / 100);
                      var temp = WeightTrend(
                        userId: CacheUser.userId,
                        weight: _currentWeight,
                        weightUnit: 'kg',
                        height: _currentHeight,
                        heightUnit: 'cm',
                        bmi: bmi,
                        gmtCreate: getCurrentDateTime(),
                      );
                      try {
                        await _userHelper.insertWeightTrendList([temp]);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        if (!context.mounted) return;
                        commonExceptionDialog(
                          context,
                          CusAL.of(context).exceptionWarningTitle,
                          e.toString(),
                        );
                      }
                    },
                    child: Text(CusAL.of(context).saveLabel),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Text buildWeightBmiText(double bmi, BuildContext context) {
  if (bmi < 18.4)
    return Text(
      CusAL.of(context).bmiLabels("0"),
      style: TextStyle(color: Colors.grey, fontSize: CusFontSizes.itemTitle),
    );
  if (bmi < 23.9)
    return Text(
      CusAL.of(context).bmiLabels("1"),
      style: TextStyle(color: Colors.green, fontSize: CusFontSizes.itemTitle),
    );
  if (bmi < 28)
    return Text(
      CusAL.of(context).bmiLabels("2"),
      style: TextStyle(color: Colors.blue, fontSize: CusFontSizes.itemTitle),
    );
  if (bmi < 35)
    return Text(
      CusAL.of(context).bmiLabels("3"),
      style: TextStyle(color: Colors.yellow, fontSize: CusFontSizes.itemTitle),
    );
  return Text(
    CusAL.of(context).bmiLabels("4"),
    style: TextStyle(color: Colors.red, fontSize: CusFontSizes.itemTitle),
  );
}
