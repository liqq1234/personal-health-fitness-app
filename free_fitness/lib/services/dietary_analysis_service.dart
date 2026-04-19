import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/dietary_state.dart';
import '../models/health_models.dart';
import '../core/constants/constants.dart';
import '../l10n/app_localizations.dart';
import '../core/apis/llm_apis.dart';
import '../models/paid_llm/common_chat_completion_state.dart';
import '../models/paid_llm/common_chat_model_spec.dart';

import '../models/user_state.dart';

class DietaryAnalysisService {
  /// 计算基于个性化信息的营养建议值
  static Map<String, double> calculatePersonalizedGoals(User user) {
    if (user.height == null ||
        user.currentWeight == null ||
        user.dateOfBirth == null) {
      return {
        'calories':
            user.rdaGoal?.toDouble() ??
            (user.gender == 'male' ? 2250.0 : 1800.0),
        'protein': user.proteinGoal ?? (user.currentWeight ?? 60.0) * 1.0,
        'fat': user.fatGoal ?? 60.0,
        'cho': user.choGoal ?? 300.0,
      };
    }

    // 1. 计算年龄
    DateTime dob = DateTime.parse(user.dateOfBirth!);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    // 2. 计算基础代谢率 (BMR) - Mifflin-St Jeor 公式
    double bmr;
    if (user.gender == 'male') {
      bmr = 10 * user.currentWeight! + 6.25 * user.height! - 5 * age + 5;
    } else {
      bmr = 10 * user.currentWeight! + 6.25 * user.height! - 5 * age - 161;
    }

    // 3. 计算总每日能量消耗 (TDEE) - 假设轻微活动系数 1.2
    double tdee = bmr * 1.2;

    // 4. 根据能量计算三大营养素推荐量
    // 蛋白质：1.2g / kg
    double protein = user.currentWeight! * 1.2;
    // 脂肪：25% 能量
    double fat = (tdee * 0.25) / 9;
    // 碳水：剩余能量
    double cho = (tdee - (protein * 4) - (fat * 9)) / 4;

    return {
      'calories': user.rdaGoal?.toDouble() ?? tdee,
      'protein': user.proteinGoal ?? protein,
      'fat': user.fatGoal ?? fat,
      'cho': user.choGoal ?? cho,
    };
  }

  /// 直接获取格式化好的建议字符串 (主要由 UI 调用)
  static String getAnalysisAdvice(
    Map<String, dynamic> analysis,
    AppLocalizations al, {
    double rDA = 2000,
  }) {
    final suggestions = analysis['suggestions'] as List<String>? ?? [];
    if (suggestions.contains('insufficient_data')) {
      return "【数据不足】请至少记录 3 天的饮食数据，以便为您提供准确的营养分析建议。";
    }
    // 由 UI 异步获取 AI 建议替代
    return "";
  }

  /// 使用 AI 解析模糊内容（如 "中午吃了300g番茄炒蛋"）
  static Future<Map<String, dynamic>> parseNaturalLanguageMeal(
    String input,
  ) async {
    String prompt =
        """
你是一位专业的营养助手。请将以下用户的饮食描述解析为结构化的 JSON 数据。
描述: "$input"

返回格式必须是以下 JSON 且不包含任何解释：
{
  "items": [
    {"name": "食材名称", "amount": "估算重量(g)", "calories": "估算热量(kcal)", "protein": "蛋白质(g)", "fat": "脂肪(g)", "carbs": "碳水(g)"}
  ],
  "total_calories": 总热量
}
""";

    try {
      final streamCancel = await getChatRespStream(
        ApiPlatform.deepseek,
        [CCMessage(role: 'user', content: prompt)],
        model: 'deepseek-chat',
        stream: false,
      );

      final resp = await streamCancel.stream.first;
      String content = resp.choices?.first.message?.content ?? "";

      if (content.isNotEmpty) {
        // 去掉可能的 Markdown 标签
        content = content.replaceAll(RegExp(r'```json|```'), '').trim();
        return json.decode(content);
      }
    } catch (e) {
      print("Fuzzy Parse Error: $e");
    }
    return {};
  }

  /// 分析摄入情况并给出建议 (核心逻辑)
  static Map<String, dynamic> analyzeWeeklyIntake(
    List<DailyFoodItemWithFoodServing> dfiwfsList,
    User user, {
    List<DietLog>? simpleDietLogs,
  }) {
    final personalizedGoals = calculatePersonalizedGoals(user);
    final proteinGoal = personalizedGoals['protein']!;
    final caloriesGoal = personalizedGoals['calories']!;
    final fatGoal = personalizedGoals['fat']!;
    final choGoal = personalizedGoals['cho']!;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dateFormat = DateFormat(constDateFormat);

    final dailyTotals = <String, FoodNutrientTotals>{};

    // 1. 处理详细饮食数据
    for (var item in dfiwfsList) {
      final itemDate = dateFormat.parse(item.dailyFoodItem.date);
      if (itemDate.isAfter(sevenDaysAgo) ||
          itemDate.isAtSameMomentAs(sevenDaysAgo)) {
        final dateKey = item.dailyFoodItem.date;
        dailyTotals.putIfAbsent(dateKey, () => FoodNutrientTotals());

        final nt = dailyTotals[dateKey]!;
        final size = item.dailyFoodItem.foodIntakeSize;
        final serving = item.servingInfo;

        nt.energy += size * serving.energy;
        nt.protein += size * serving.protein;
        nt.dietaryFiber += size * (serving.dietaryFiber ?? 0);
        nt.totalCHO += size * serving.totalCarbohydrate;
        nt.totalFat += size * serving.totalFat;
      }
    }

    // 2. 处理简易饮食日志 (Local/Quick Entry)
    if (simpleDietLogs != null) {
      for (var log in simpleDietLogs) {
        final logDate = dateFormat.parse(log.date);
        if (logDate.isAfter(sevenDaysAgo) ||
            logDate.isAtSameMomentAs(sevenDaysAgo)) {
          final dateKey = log.date;
          dailyTotals.putIfAbsent(dateKey, () => FoodNutrientTotals());

          final nt = dailyTotals[dateKey]!;
          nt.energy += log.calories * oneCalToKjRatio;
          nt.protein += log.protein;
          // 简易记录假设 0 脂肪和碳水（如果 DietLog 以后扩展了可以加上）
        }
      }
    }

    final recordedDays = dailyTotals.length;
    double avgProtein = 0;
    double avgFiber = 0;
    double avgCalories = 0;
    double avgFat = 0;
    double avgCho = 0;

    dailyTotals.values.forEach((nt) {
      avgProtein += nt.protein;
      avgFiber += nt.dietaryFiber;
      avgCalories += (nt.energy / oneCalToKjRatio);
      avgFat += nt.totalFat;
      avgCho += nt.totalCHO;
    });

    if (recordedDays < 3) {
      return {
        'avgProtein': 0.0,
        'avgFiber': 0.0,
        'avgCalories': 0.0,
        'proteinThreshold': proteinGoal,
        'caloriesThreshold': caloriesGoal,
        'suggestions': ['insufficient_data'],
        'hasAdvice': true,
        'dailyTotals': dailyTotals,
      };
    }

    avgProtein /= recordedDays;
    avgFiber /= recordedDays;
    avgCalories /= recordedDays;
    avgFat /= recordedDays;
    avgCho /= recordedDays;

    final suggestions = <String>[];

    // 基于个性化目标的差值判断
    if (avgProtein < proteinGoal * 0.8) suggestions.add('protein_deficit');
    if (avgCalories > caloriesGoal * 1.1) suggestions.add('calories_excess');
    if (avgCalories < caloriesGoal * 0.8) suggestions.add('calories_deficit');
    if (avgFiber < 25.0) suggestions.add('fiber_deficit');

    return {
      'avgProtein': avgProtein,
      'avgFiber': avgFiber,
      'avgCalories': avgCalories,
      'avgFat': avgFat,
      'avgCho': avgCho,
      'proteinThreshold': proteinGoal,
      'caloriesThreshold': caloriesGoal,
      'fatThreshold': fatGoal,
      'choThreshold': choGoal,
      'fiberThreshold': 25.0,
      'suggestions': suggestions,
      'hasAdvice': suggestions.isNotEmpty,
      'dailyTotals': dailyTotals,
      'userProfile': {
        'age':
            (DateTime.now().year -
            DateTime.parse(user.dateOfBirth ?? "2000-01-01").year),
        'gender': user.gender,
        'weight': user.currentWeight,
        'height': user.height,
      },
    };
  }

  /// 获取流式 AI 饮食建议
  static Future<String> getAIDietaryAnalysis(
    Map<String, dynamic> analysis,
    List<DietLog> weeklyLogs,
    double rDA,
  ) async {
    final suggestions = analysis['suggestions'] as List<String>? ?? [];
    if (suggestions.contains('insufficient_data')) {
      return "【数据不足】请至少记录 3 天的饮食数据，以便 AI 为您提供准确的个人营养分析。";
    }

    double avgCal = analysis['avgCalories'] ?? 0;
    double avgPro = analysis['avgProtein'] ?? 0;
    double avgFib = analysis['avgFiber'] ?? 0;
    double calGoal = analysis['caloriesThreshold'] ?? rDA;
    double proGoal = analysis['proteinThreshold'] ?? 60;

    String foodSummary = weeklyLogs
        .take(15)
        .map((l) => "${l.foodName}(${l.calories}kcal)")
        .join(", ");

    final userProfile = analysis['userProfile'] as Map<String, dynamic>? ?? {};

    String prompt =
        """
你是一位极致专业的私人营养师。请根据以下用户数据给出深度的个性化分析建议：

[个人资料]
- 性态: ${userProfile['gender'] == 'male' ? '男' : '女'}
- 年龄: ${userProfile['age']}岁, 体重: ${userProfile['weight']}kg, 身高: ${userProfile['height']}cm

[营养状况(过去7天平均)]
- 热量: ${avgCal.toStringAsFixed(1)} kcal / 目标: ${calGoal.toStringAsFixed(0)} kcal
- 蛋白质: ${avgPro.toStringAsFixed(1)} g / 目标: ${proGoal.toStringAsFixed(1)} g
- 膳食纤维: ${avgFib.toStringAsFixed(1)} g

[近期食物记录]
$foodSummary

[任务]
1. 对比目标指出明显的缺口（如：热量缺口、蛋白不足、摄入过咸/油等）。
2. 提供 2-3 条极具操作性的建议。
3. 必须推荐具体的补漏食物（例如：蛋白质不足推荐鸡胸肉、牛腱子；纤维不足推荐西兰花、燕麦）。
4. 语言要口语化、鼓励性质，直接输出建议内容，不要任何寒暄。
总字数控制在 150 字以内。
""";

    try {
      final streamCancel = await getChatRespStream(
        ApiPlatform.deepseek,
        [CCMessage(role: 'user', content: prompt)],
        model: 'deepseek-chat',
        stream: false,
      );

      final resp = await streamCancel.stream.first;
      return resp.choices?.first.message?.content ?? "";
    } catch (e) {
      print("AI Analysis Error: $e");
      return "暂时无法获取 AI 建议，请检查网络连接。";
    }
  }
}
