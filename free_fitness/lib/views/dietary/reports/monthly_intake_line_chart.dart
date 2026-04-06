import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/constants.dart';
import '../../../models/dietary_state.dart';

class MonthlyIntakeLineChart extends StatelessWidget {
  final Map<String, FoodNutrientTotals> fntMap;
  final CusChartType type;

  const MonthlyIntakeLineChart({
    super.key,
    required this.fntMap,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: EdgeInsets.only(
          right: 18.sp,
          left: 12.sp,
          top: 24.sp,
          bottom: 12.sp,
        ),
        child: LineChart(mainData(context)),
      ),
    );
  }

  LineChartData mainData(BuildContext context) {
    // 提取当月所有日期并排序
    List<String> sortedDates = fntMap.keys.toList()..sort();
    if (sortedDates.isEmpty) return LineChartData();

    // 转换为横坐标 (0 到 n-1)
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      var fnt = fntMap[sortedDates[i]]!;
      double yValue = (type == CusChartType.calory)
          ? fnt.calorie
          : (fnt.totalCHO + fnt.totalFat + fnt.protein);
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 500,
        verticalInterval: 5,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.black12, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Colors.black12, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 5,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < sortedDates.length) {
                // 每隔 5 天显示一次日期
                if (index % 5 == 0 || index == sortedDates.length - 1) {
                  DateTime date = DateFormat(
                    constDateFormat,
                  ).parse(sortedDates[index]);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  );
                }
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1000,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10.sp),
                ),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.cyanAccent],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withOpacity(0.3),
                Colors.cyanAccent.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
