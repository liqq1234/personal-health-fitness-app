import 'package:intl/intl.dart';
import '../models/dietary_state.dart';
import '../models/health_models.dart';
import '../core/constants/constants.dart';
import '../l10n/app_localizations.dart';
import '../core/apis/llm_apis.dart';
import '../models/paid_llm/common_chat_completion_state.dart';
import '../models/paid_llm/common_chat_model_spec.dart';

class DietaryAnalysisService {
  /// 分析过去 7 天的平均营养摄入情况并给出建议
  /// [dfiwfsList] 包含所有历史数据的列表，由于可能跨越多天，内部需按天过滤
  static Map<String, dynamic> analyzeWeeklyIntake(
    List<DailyFoodItemWithFoodServing> dfiwfsList,
    double userWeight, // 用于计算蛋白质推荐量
    int rdaGoal, {
    List<DietLog>? simpleDietLogs,
  }) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dateFormat = DateFormat(constDateFormat);

    final dailyTotals = <String, FoodNutrientTotals>{};

    // 1. 处理详细饮食数据 (Cloud/Detailed)
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
          // DietLog 中的 calories 是大卡，转为 energy (千焦) 以保持一致
          nt.energy += log.calories * oneCalToKjRatio;
          nt.protein += log.protein;
          // 简易记录没有纤维等信息，保持 0
        }
      }
    }

    final recordedDays = dailyTotals.length;
    double avgProtein = 0;
    double avgFiber = 0;
    double avgCalories = 0;

    dailyTotals.values.forEach((nt) {
      avgProtein += nt.protein;
      avgFiber += nt.dietaryFiber;
      avgCalories += (nt.energy / oneCalToKjRatio);
    });

    // 如果数据不足 3 天，不计算平均值，直接返回数据不足
    if (recordedDays < 3) {
      return {
        'avgProtein': 0.0,
        'avgFiber': 0.0,
        'avgCalories': 0.0,
        'proteinThreshold': 0.0,
        'fiberThreshold': 0.0,
        'suggestions': ['insufficient_data'],
        'hasAdvice': true,
        'dailyTotals': dailyTotals,
      };
    }

    // 平均值基于实际记录的天数计算，这样即便刚开始用也能得到合理建议
    avgProtein /= recordedDays;
    avgFiber /= recordedDays;
    avgCalories /= recordedDays;

    final proteinThreshold = userWeight > 0 ? userWeight * 1.0 : 50.0;
    const fiberThreshold = 25.0;

    final suggestions = <String>[];

    bool proteinDeficit = avgProtein < proteinThreshold;
    bool fiberDeficit = avgFiber < fiberThreshold;

    if (proteinDeficit) {
      suggestions.add('protein_deficit');
    }
    if (fiberDeficit) {
      suggestions.add('fiber_deficit');
    }

    return {
      'avgProtein': avgProtein,
      'avgFiber': avgFiber,
      'avgCalories': avgCalories,
      'proteinThreshold': proteinThreshold,
      'fiberThreshold': fiberThreshold,
      'suggestions': suggestions,
      'hasAdvice': suggestions.isNotEmpty,
      'dailyTotals': dailyTotals,
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

    // 用户要求去掉之前的“蛋白不足/纤维不足”硬编码规则
    // 直接返回空，UI 将由异步获取的 AI 建议替代
    return "";
  }

  /// 使用 AI (DeepSeek) 进行深度饮食分析
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

    String foodSummary = weeklyLogs
        .take(15)
        .map((l) => "${l.foodName}(${l.calories}kcal)")
        .join(", ");

    String prompt =
        """
你是一位专业的营养师。以下是用户过去7天的饮食数据包：
- 平均每日摄入: ${avgCal.toStringAsFixed(1)} kcal (每日目标: ${rDA.toStringAsFixed(0)} kcal)
- 平均每日蛋白质: ${avgPro.toStringAsFixed(1)} g
- 平均每日膳食纤维: ${avgFib.toStringAsFixed(1)} g
近期记录的部分食物: $foodSummary

请根据以上宏观数据和具体食物，给出2-3条非常具体、专业且口语化的个性化改善建议。
如果蛋白质或纤维明显不足，请推荐具体的食物进行补充。
回复要求：直接给建议，不要开场白，总字数控制在100字以内，使用中文。
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
        return content;
      }
      return "";
    } catch (e) {
      print("AI Analysis Error: $e");
      return ""; // 失败时返回空，UI 依然展示基础建议
    }
  }
}
