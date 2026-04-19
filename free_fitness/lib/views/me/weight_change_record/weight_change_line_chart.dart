import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/storage/db_user_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';

class WeightChangeLineChart extends StatefulWidget {
  final User user;

  const WeightChangeLineChart({super.key, required this.user});

  @override
  State<WeightChangeLineChart> createState() => _WeightChangeLineChartState();
}

class _WeightChangeLineChartState extends State<WeightChangeLineChart> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 使用 ValueNotifier 隔离状态，避免全量 rebuild 冲突
  final ValueNotifier<List<int>> _tooltipNotifier = ValueNotifier<List<int>>([
    0,
    0,
  ]);
  final ValueNotifier<List<WeightTrend>> _trendsNotifier =
      ValueNotifier<List<WeightTrend>>([]);
  final ValueNotifier<List<FlSpot>> _spotsNotifier =
      ValueNotifier<List<FlSpot>>([]);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(false);

  double minWeight = 0;
  double maxWeight = 0;
  double spotWidth = 60.sp;

  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 延迟到首帧之后加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) getWeightData();
    });
  }

  @override
  void dispose() {
    _tooltipNotifier.dispose();
    _trendsNotifier.dispose();
    _spotsNotifier.dispose();
    _loadingNotifier.dispose();
    super.dispose();
  }

  Future<void> getWeightData({String? startDate, String? endDate}) async {
    if (_loadingNotifier.value) return;

    _loadingNotifier.value = true;

    try {
      var tempList = await _userHelper.queryWeightTrendByUser(
        userId: widget.user.userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      if (tempList.isEmpty) {
        _trendsNotifier.value = [];
        _spotsNotifier.value = [];
        _loadingNotifier.value = false;
        return;
      }

      minWeight = tempList[0].weight;
      maxWeight = tempList[0].weight;
      int minWeightIndex = 0;
      int maxWeightIndex = 0;
      List<FlSpot> spots = [];

      for (var i = 0; i < tempList.length; i++) {
        var e = tempList[i];
        if (e.weight < minWeight) {
          minWeight = e.weight;
          minWeightIndex = i;
        }
        if (e.weight > maxWeight) {
          maxWeight = e.weight;
          maxWeightIndex = i;
        }
        spots.add(FlSpot(i.toDouble(), e.weight));
      }

      if (mounted) {
        _trendsNotifier.value = tempList;
        _spotsNotifier.value = spots;
        _tooltipNotifier.value = [minWeightIndex, maxWeightIndex];
        _loadingNotifier.value = false;
      }
    } catch (e) {
      debugPrint("Load weight data failed: $e");
      if (mounted) _loadingNotifier.value = false;
    }
  }

  // 左侧的标签(体重)
  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    var unit = "kg";
    return SideTitleWidget(
      meta: meta,
      child: Text(
        "${meta.formattedValue}$unit",
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 底部的标签(日期)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final trends = _trendsNotifier.value;
    if (value.toInt() >= trends.length) return Container();

    var temp = trends[value.toInt()].gmtCreate;
    var tempDate = temp.split(" ")[0].split("-");
    String text = tempDate.sublist(tempDate.length - 2).join("-");

    if (spotWidth >= 60) {
      text =
          '${tempDate.sublist(tempDate.length - 2).join("-")}\n${temp.split(" ")[1]}';
    } else if (spotWidth >= 30) {
      text = tempDate.sublist(tempDate.length - 2).join("-");
    } else {
      text = temp.split(" ")[0].split("-")[2];
    }

    return SideTitleWidget(
      meta: meta,
      fitInside: SideTitleFitInsideData.disable(),
      child: Text(text, style: TextStyle(fontSize: CusFontSizes.flagTiny)),
    );
  }

  Future<void> saveChartImage() async {
    try {
      var dir = Directory('/storage/emulated/0/free-fitness/images');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File(
        '${dir.path}/体重趋势图_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      RenderRepaintBoundary boundary =
          _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.sp);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
        ToastUtils.showToast("图片已保存在手机下/${file.path.split("/0/").last}");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WeightTrend>>(
      valueListenable: _trendsNotifier,
      builder: (context, trends, _) {
        if (trends.isEmpty) {
          return ValueListenableBuilder<bool>(
            valueListenable: _loadingNotifier,
            builder: (context, isLoading, _) {
              if (isLoading)
                return Center(
                  child: SizedBox(
                    height: 300.sp,
                    child: const CircularProgressIndicator(),
                  ),
                );
              return SizedBox(
                height: 300.sp,
                child: Center(child: Text(CusAL.of(context).noRecordNote)),
              );
            },
          );
        }
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    var temp = getStartEndDateString(7);
                    getWeightData(startDate: temp[0], endDate: temp[1]);
                  },
                  child: Text(CusAL.of(context).lastDayLabels("7")),
                ),
                TextButton(
                  onPressed: () {
                    var temp = getStartEndDateString(30);
                    getWeightData(startDate: temp[0], endDate: temp[1]);
                  },
                  child: Text(CusAL.of(context).lastDayLabels("30")),
                ),
                TextButton(
                  onPressed: () {
                    var temp = getStartEndDateString(90);
                    getWeightData(startDate: temp[0], endDate: temp[1]);
                  },
                  child: Text(CusAL.of(context).lastDayLabels("90")),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: saveChartImage,
                  icon: Icon(
                    Icons.download,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (spotWidth >= 50.sp)
                        spotWidth -= 10.sp;
                      else if (spotWidth >= 25.sp)
                        spotWidth -= 5.sp;
                    });
                  },
                  icon: Icon(
                    Icons.zoom_out,
                    color: spotWidth <= 20.sp
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (spotWidth <= 110.sp) spotWidth += 10.sp;
                    });
                  },
                  icon: Icon(
                    Icons.zoom_in,
                    color: spotWidth >= 120.sp
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _loadingNotifier,
              builder: (context, isLoading, _) {
                if (isLoading)
                  return Center(
                    child: SizedBox(
                      height: 300.sp,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                return _buildLineChart(trends);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineChart(List<WeightTrend> trends) {
    return ValueListenableBuilder<List<FlSpot>>(
      valueListenable: _spotsNotifier,
      builder: (context, spots, _) {
        final lineBarsData = [
          LineChartBarData(
            showingIndicators: _tooltipNotifier.value,
            spots: spots,
            barWidth: 2.sp,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.pink, Colors.red],
              stops: [0.1, 0.4, 0.9],
            ),
          ),
        ];

        final tooltipsOnBar = lineBarsData[0];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: RepaintBoundary(
            key: _chartKey,
            child: Container(
              padding: EdgeInsets.fromLTRB(10.sp, 50.sp, 30.sp, 10.sp),
              width: (spots.length * spotWidth) + 80.sp,
              height: 300.sp,
              child: ValueListenableBuilder<List<int>>(
                valueListenable: _tooltipNotifier,
                builder: (context, tooltips, _) {
                  return LineChart(
                    LineChartData(
                      showingTooltipIndicators: tooltips.map((index) {
                        if (index >= spots.length)
                          return ShowingTooltipIndicators([]);
                        return ShowingTooltipIndicators([
                          LineBarSpot(tooltipsOnBar, 0, spots[index]),
                        ]);
                      }).toList(),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        touchCallback: (event, response) {
                          if (response == null || response.lineBarSpots == null)
                            return;
                          if (event is FlTapUpEvent) {
                            final spotIndex =
                                response.lineBarSpots!.first.spotIndex;
                            final current = List<int>.from(
                              _tooltipNotifier.value,
                            );
                            if (current.contains(spotIndex))
                              current.remove(spotIndex);
                            else
                              current.add(spotIndex);
                            _tooltipNotifier.value = current;
                          }
                        },
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              const FlLine(color: Colors.pink),
                              FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 5.sp,
                                          color: lerpGradient(
                                            barData.gradient!.colors,
                                            barData.gradient!.stops!,
                                            percent / 100,
                                          ),
                                          strokeWidth: 2.sp,
                                          strokeColor: Colors.grey,
                                        ),
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.pink,
                          tooltipBorderRadius: BorderRadius.circular(8.sp),
                          getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                            return lineBarsSpot.map((lineBarSpot) {
                              return LineTooltipItem(
                                lineBarSpot.y.toStringAsFixed(2),
                                TextStyle(
                                  fontSize: CusFontSizes.itemSubContent,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: lineBarsData,
                      minY:
                          trends
                              .map((e) => e.weight)
                              .reduce((a, b) => a < b ? a : b)
                              .floorToDouble() -
                          3,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: _leftTitles,
                            reservedSize: 50.sp,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: bottomTitleWidgets,
                            reservedSize: 40.sp,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  if (colors.isEmpty) throw ArgumentError('"colors" is empty.');
  if (colors.length == 1) return colors[0];
  if (stops.length != colors.length) {
    stops = [];
    colors.asMap().forEach((index, color) {
      final percent = 1.0 / (colors.length - 1);
      stops.add(percent * index);
    });
  }
  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s];
    final rightStop = stops[s + 1];
    final leftColor = colors[s];
    final rightColor = colors[s + 1];
    if (t <= leftStop) return leftColor;
    if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}
