import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/constants.dart';
import '../../../core/storage/db_training_helper.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../core/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';
import '../../../services/notification_service.dart';
import 'group_list.dart';

///
/// 2023-11-22 和workout index 基本类似，几乎一模一样
/// 2024-11-14
/// 但是类型、文字等不相同，本来想抽象类复用的，暂时没弄
///
class TrainingPlans extends StatefulWidget {
  const TrainingPlans({super.key});

  @override
  State<TrainingPlans> createState() => _TrainingPlansState();
}

class _TrainingPlansState extends State<TrainingPlans> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();
  // plan查询表单的key
  final _queryFormKey = GlobalKey<FormBuilderState>();
  // plan新增保单的key
  final _addFormKey = GlobalKey<FormBuilderState>();

  // 展示计划列表(训练列表一次性查询所有，应该不会太多)
  List<PlanWithGroups> planList = [];

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getPlanList();
  }

  // 查询已有的训练
  Future<void> getPlanList() async {
    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // 等待查询结果
    List<PlanWithGroups> temp;
    if (conditionMap.isEmpty) {
      temp = await _dbHelper.searchPlanWithGroups();
    } else {
      temp = await _dbHelper.searchPlanWithGroups(
        planName: conditionMap["plan_name"],
        planCategory: conditionMap["plan_category"],
        planLevel: conditionMap["plan_level"],
      );
    }

    // 设置查询结果
    if (!mounted) return;
    setState(() {
      // ？？？因为没有分页查询，所有这里直接替换已有的数组
      planList = temp;
      // 重置状态为查询完成
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${CusAL.of(context).plans}\n',
                style: TextStyle(
                  fontSize: CusFontSizes.pageTitle,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: CusAL.of(context).itemCount(planList.length),
                style: TextStyle(
                  fontSize: CusFontSizes.pageAppendix,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        actions: [
          /// 新增训练组基本信息
          IconButton(icon: const Icon(Icons.add), onPressed: _modifyPlanInfo),
        ],
      ),
      body: Column(
        children: [
          /// 查询条件区域
          FormBuilder(
            key: _queryFormKey,
            child: Card(
              elevation: 5.sp,
              child: Column(
                children: [
                  _buildQueryArea(),
                  SizedBox(height: 10.sp),
                ],
              ),
            ),
          ),
          isLoading
              ? buildLoader(isLoading)
              : Expanded(
                  child: ListView.builder(
                    itemCount: planList.length,
                    itemBuilder: (context, index) {
                      final planItem = planList[index];
                      return _buildPlanCard(planItem);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // 条件查询区域(和action list一模一样)
  Row _buildQueryArea() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: cusFormBuilerTextField(
                      "plan_name",
                      labelText: CusAL.of(context).planQuerys('0'),
                    ),
                  ),
                  SizedBox(
                    width: 50.sp,
                    height: 36.sp,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _queryFormKey.currentState?.reset();
                          // 2023-12-12 不知道为什么，reset对下拉选中的没有效，所以手动清除
                          _queryFormKey.currentState?.fields['plan_category']
                              ?.didChange(null);
                          _queryFormKey.currentState?.fields['plan_level']
                              ?.didChange(null);

                          conditionMap = {};
                          getPlanList();
                        });
                        // 如果有键盘就收起键盘
                        FocusScope.of(context).focusedChild?.unfocus();
                      },
                      child: Text(
                        CusAL.of(context).resetLabel,
                        style: TextStyle(
                          fontSize: CusFontSizes.pageAppendix,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: cusFormBuilerDropdown(
                      "plan_category",
                      categoryOptions,
                      labelText: CusAL.of(context).planQuerys('1'),
                    ),
                  ),
                  Flexible(
                    child: cusFormBuilerDropdown(
                      "plan_level",
                      levelOptions,
                      labelText: CusAL.of(context).planQuerys('2'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 50.sp,
          alignment: Alignment.center,
          child: IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            onPressed: () {
              if (_queryFormKey.currentState!.saveAndValidate()) {
                setState(() {
                  conditionMap = _queryFormKey.currentState!.value;
                  getPlanList();
                });
              }
              FocusScope.of(context).focusedChild?.unfocus();
            },
          ),
        ),
      ],
    );
  }

  // 计划数据卡片(和action list几乎一模一样)
  Card _buildPlanCard(PlanWithGroups planItem) {
    return Card(
      elevation: 2.sp,
      child: ListTile(
        leading: Icon(Icons.alarm_on, size: CusIconSizes.iconLarge),
        title: Text(
          planItem.plan.planName,
          style: TextStyle(
            fontSize: CusFontSizes.itemTitle,
            color: Theme.of(context).primaryColor,
          ),
        ),
        subtitle: RichText(
          textAlign: TextAlign.left,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text:
                    '${planItem.groupDetailList.length} ${CusAL.of(context).workouts}  ',
                // 这里只是取text的默认颜色，避免浅主题时文字不显示(好像默认是白色，反正看不到)
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              TextSpan(
                text: getCusLabelText(planItem.plan.planLevel, levelOptions),
                style: TextStyle(color: Colors.green[500]),
              ),
              TextSpan(
                // 可以不和exercise用同一个分类，但要单独列一个
                text:
                    '  ${getCusLabelText(planItem.plan.planCategory, categoryOptions)}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              if (planItem.plan.sportType != null)
                TextSpan(
                  text: '  [${planItem.plan.sportType}]',
                  style: TextStyle(color: Colors.blue[500]),
                ),
              if (planItem.plan.startTime != null)
                TextSpan(
                  text: ' \n⏰ ${planItem.plan.startTime}',
                  style: TextStyle(
                    fontSize: CusFontSizes.pageAppendix,
                    color: Colors.orange[700],
                  ),
                ),
            ],
          ),
        ),

        trailing: SizedBox(
          width: 30.sp,
          child: IconButton(
            icon: Icon(
              Icons.edit,
              size: CusIconSizes.iconNormal,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _modifyPlanInfo(planItem: planItem.plan);
            },
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupList(planItem: planItem.plan),
            ),
          ).then((value) {
            getPlanList();
          });
        },
        // 长按点击弹窗提示是否删除
        onLongPress: () async {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(CusAL.of(context).deleteConfirm),
                content: Text(
                  CusAL.of(context).planDeleteAlert(planItem.plan.planName),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(CusAL.of(context).cancelLabel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(CusAL.of(context).confirmLabel),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value != null && value) {
              try {
                await _dbHelper.deletePlanById(planItem.plan.planId!);

                // 删除后重新查询
                getPlanList();
              } catch (e) {
                if (!mounted) return;
                commonExceptionDialog(
                  context,
                  CusAL.of(context).exceptionWarningTitle,
                  e.toString(),
                );
              }
            }
          });
        },
      ),
    );
  }

  // 修改计划基本信息的弹窗
  // ？？？这和训练的基本信息修改也一样，但弹窗的宽度可以想办法在自定义下
  void _modifyPlanInfo({TrainingPlan? planItem}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            planItem != null
                ? CusAL.of(context).modifyPlanLabels('1')
                : CusAL.of(context).modifyPlanLabels('0'),
          ),
          content: _buildPlanModifyForm(planItem),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(CusAL.of(context).cancelLabel),
            ),
            TextButton(
              onPressed: () {
                _clickPlanModifyButton(planItem);
              },
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );
  }

  // 构建计划修改表单
  FormBuilder _buildPlanModifyForm(TrainingPlan? planItem) {
    return FormBuilder(
      key: _addFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            cusFormBuilerTextField(
              "plan_name",
              labelText: '*${CusAL.of(context).modifyPlanLabels('2')}',
              initialValue: planItem?.planName,
              validator: FormBuilderValidators.required(),
            ),
            cusFormBuilerTextField(
              "plan_code",
              labelText: '*${CusAL.of(context).modifyPlanLabels('3')}',
              initialValue: planItem?.planCode,
              validator: FormBuilderValidators.required(),
            ),
            cusFormBuilerDropdown(
              "plan_category",
              categoryOptions,
              labelText: '*${CusAL.of(context).modifyPlanLabels('4')}',
              initialValue: planItem?.planCategory,
              validator: FormBuilderValidators.required(),
            ),
            cusFormBuilerDropdown(
              "plan_level",
              levelOptions,
              labelText: '*${CusAL.of(context).modifyPlanLabels('5')}',
              initialValue: planItem?.planLevel,
              validator: FormBuilderValidators.required(),
            ),

            // 2023-12-30 实际这个周期不需要用户手动输入，它就是该plan对应的group列表的长度
            // cusFormBuilerTextField(
            //   "plan_period",
            //   labelText: '*${CusAL.of(context).modifyPlanLabels('6')}',
            //   initialValue: planItem?.planPeriod.toString(),
            //   validator: FormBuilderValidators.compose([
            //     FormBuilderValidators.required(),
            //   ]),
            //   // 正则来只允许输入数字
            //   inputFormatters: [
            //     FilteringTextInputFormatter.digitsOnly,
            //   ],
            //   keyboardType: TextInputType.number,
            // ),
            cusFormBuilerTextField(
              "description",
              labelText: '*${CusAL.of(context).modifyPlanLabels('7')}',
              initialValue: planItem?.description,
              maxLines: 3,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            cusFormBuilerTextField(
              "sport_type",
              labelText: CusAL.of(context).modifyPlanLabels('8'),
              initialValue: planItem?.sportType,
            ),
            Row(
              children: [
                Expanded(
                  child: cusFormBuilerTextField(
                    "total_sets",
                    labelText: CusAL.of(context).modifyPlanLabels('9'),
                    initialValue: planItem?.totalSets?.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                Expanded(
                  child: cusFormBuilerTextField(
                    "rest_duration",
                    labelText: CusAL.of(context).modifyPlanLabels('10'),
                    initialValue: planItem?.restDuration?.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: "start_time",
                    inputType: InputType.time,
                    initialValue: planItem?.startTime != null
                        ? DateTime(
                            2000,
                            1,
                            1,
                            int.parse(planItem!.startTime!.split(':')[0]),
                            int.parse(planItem!.startTime!.split(':')[1]),
                          )
                        : null,
                    decoration: const InputDecoration(labelText: '训练开始时间'),
                    format: DateFormat("HH:mm"),
                    valueTransformer: (val) =>
                        val != null ? DateFormat("HH:mm").format(val) : null,
                  ),
                ),
                Expanded(
                  child: cusFormBuilerTextField(
                    "reminder_minutes",
                    labelText: CusAL.of(context).modifyPlanLabels('11'),
                    initialValue: planItem?.reminderMinutes?.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建确认编辑的回调
  Future<void> _clickPlanModifyButton(TrainingPlan? planItem) async {
    if (_addFormKey.currentState!.saveAndValidate()) {
      // 获取表单数值
      Map<String, dynamic> formData = _addFormKey.currentState!.value;

      // 2023-12-30 实际这个周期不需要用户手动输入，它就是该plan对应的group列表的长度
      var temp = TrainingPlan.fromMap(formData);

      try {
        // 如果是新增
        if (planItem == null) {
          var planId = await _dbHelper.insertTrainingPlan(temp);
          temp.planId = planId;

          // 预约提醒
          _schedulePlanReminder(temp);

          if (!mounted) return;
          Navigator.of(context).pop();

          // 新增计划完成后弹窗关闭，同时进入其训练组列表页面让用户进行训练的添加
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupList(planItem: temp)),
          ).then((value) {
            // 新增plan基本信息后直接跳入训练列表，在其中完成新增训练操作之后该计划就会变；
            // 暂时返回这个页面时都重新加载最新的计划列表数据
            getPlanList();
          });
        } else {
          // 如果是修改
          temp.planId = planItem.planId!;
          await _dbHelper.updateTrainingPlanById(planItem.planId!, temp);

          // 预约提醒
          _schedulePlanReminder(temp);

          // 如果是修改就返回训练组列表，而不是进入动作列表
          if (!mounted) return;
          Navigator.of(context).pop();
          getPlanList();
        }
      } catch (e) {
        if (!mounted) return;
        commonExceptionDialog(
          context,
          CusAL.of(context).exceptionWarningTitle,
          e.toString(),
        );
      }
    }
  }

  void _schedulePlanReminder(TrainingPlan plan) {
    if (plan.startTime != null && plan.reminderMinutes != null) {
      final timeParts = plan.startTime!.split(':');
      var hour = int.parse(timeParts[0]);
      var minute = int.parse(timeParts[1]);

      // 提前提醒分钟
      var totalMinutes = hour * 60 + minute - plan.reminderMinutes!;
      if (totalMinutes < 0) totalMinutes += 24 * 60;

      hour = totalMinutes ~/ 60;
      minute = totalMinutes % 60;

      NotificationService().scheduleDailyTrainingReminder(
        id: plan.planId ?? 100, // 使用 planId 作为通知 ID
        title: '训练提醒',
        body: '你的训练计划 "${plan.planName}" 即将开始，请做好准备！',
        hour: hour,
        minute: minute,
      );
    }
  }
}
