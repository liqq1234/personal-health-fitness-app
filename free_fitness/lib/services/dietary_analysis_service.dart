import 'package:intl/intl.dart';
import '../models/dietary_state.dart';
import '../core/constants/constants.dart';
import '../l10n/app_localizations.dart';

class DietaryAnalysisService {
  /// 分析过去 7 天的平均营养摄入情况并给出建议
  /// [dfiwfsList] 包含所有历史数据的列表，由于可能跨越多天，内部需按天过滤
  static Map<String, dynamic> analyzeWeeklyIntake(
    List<DailyFoodItemWithFoodServing> dfiwfsList,
    double userWeight, // 用于计算蛋白质推荐量
    int rdaGoal,
  ) {
    // ... (rest of the analyzeWeeklyIntake method) ...
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dateFormat = DateFormat(constDateFormat);

    final dailyTotals = <String, FoodNutrientTotals>{};

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

    const daysCount = 7;
    double avgProtein = 0;
    double avgFiber = 0;
    double avgCalories = 0;

    dailyTotals.values.forEach((nt) {
      avgProtein += nt.protein;
      avgFiber += nt.dietaryFiber;
      avgCalories += (nt.energy / oneCalToKjRatio);
    });

    avgProtein /= daysCount;
    avgFiber /= daysCount;
    avgCalories /= daysCount;

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
    Map<String, FoodNutrientTotals> weekData,
    AppLocalizations al, {
    double rDA = 2000,
  }) {
    if (weekData.isEmpty) return al.noRecordNote;

    double totalProtein = 0;
    double totalFiber = 0;
    // 假设分析过去7天的数据（通过 weekData 传入）
    for (var nt in weekData.values) {
      totalProtein += nt.protein;
      totalFiber += nt.dietaryFiber;
    }

    double avgProtein = totalProtein / 7;
    double avgFiber = totalFiber / 7;

    double proteinThreshold = (rDA * 0.15) / 4;
    double fiberThreshold = 25.0;

    List<String> advices = [];
    if (avgProtein < proteinThreshold) {
      advices.add(al.proteinDeficitAdvice);
    }
    if (avgFiber < fiberThreshold) {
      advices.add(al.fiberDeficitAdvice);
    }

    if (advices.isEmpty) {
      return al.dietaryGoodAdvice;
    }

    // 这里可以根据具体的缺失情况，硬编码一些食物建议（如果多语言文件中没有的话，但目前文件里已经有一些了）
    // 为了满足用户“提醒多补充此类食物摄入”的要求，我们可以让建议更显眼
    return advices.join('\n');
  }
}
