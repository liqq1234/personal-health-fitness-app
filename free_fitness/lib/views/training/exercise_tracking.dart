import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';
import '../../core/storage/db_health_helper.dart';
import '../../core/storage/db_training_helper.dart';
import '../../core/constants/constants.dart';
import '../../models/health_models.dart';
import '../../models/training_state.dart';
import '../../services/notification_service.dart';
import '../../services/pedometer_service.dart';

class ExerciseTracking extends StatefulWidget {
  const ExerciseTracking({super.key});

  @override
  State<ExerciseTracking> createState() => _ExerciseTrackingState();
}

class _ExerciseTrackingState extends State<ExerciseTracking> {
  final MapController _mapController = MapController();
  final List<LatLng> _pathPoints = [];
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;

  // Stats
  double _totalDistance = 0; // in meters
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTimeString = "00:00:00";
  double _currentPace = 0; // min/km
  double _calories = 0;

  // Simulator info
  bool get _isSimulator => !Platform.isAndroid && !Platform.isIOS;
  Timer? _simulationTimer;

  @override
  void dispose() {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTimeString = _formatDuration(_stopwatch.elapsed);
          _calculateStats();
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _calculateStats() {
    if (_totalDistance > 0 && _stopwatch.elapsed.inSeconds > 0) {
      // Pace: min / km
      double distanceKm = _totalDistance / 1000;
      double minutes = _stopwatch.elapsed.inSeconds / 60;
      if (distanceKm > 0) {
        _currentPace = minutes / distanceKm;
      }

      // Calories: MET * weight * time_hours
      // Assuming average MET for running is 8.0, and avg weight is 70kg
      double hours = minutes / 60;
      _calories = 8.0 * 70 * hours;
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    if (!_isSimulator) {
      // Permission check...
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('请开启 GPS 定位服务');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('位置权限被永久拒绝，请在设置中开启');
        return;
      }
    }

    setState(() {
      _isTracking = true;
      _pathPoints.clear();
      _totalDistance = 0;
      _calories = 0;
      _currentPace = 0;
      _stopwatch.reset();
      _stopwatch.start();
    });
    _startTimer();
    WakelockPlus.enable();

    if (!_isSimulator) {
      await NotificationService().showNotification(
        id: 999,
        title: '运动追踪进行中',
        body: '正在实时记录您的位置和运动数据...',
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 3,
            ),
          ).listen((Position position) {
            _onLocationUpdate(
              position.latitude,
              position.longitude,
              position.accuracy,
            );
          });
    } else {
      // Simulation: 围绕标准400米操场跑圈
      // 椭圆形跑道坐标点（模拟标准田径场）
      final List<List<double>> trackRoute = [
        // 南侧直道（从西向东）
        [39.9580, 116.3680],
        [39.9580, 116.3684],
        [39.9580, 116.3688],
        [39.9580, 116.3692],
        [39.9580, 116.3696],
        [39.9580, 116.3700],
        // 东侧弯道（从南向北）
        [39.9581, 116.3702],
        [39.9583, 116.3703],
        [39.9585, 116.3703],
        [39.9587, 116.3703],
        [39.9589, 116.3702],
        [39.9590, 116.3700],
        // 北侧直道（从东向西）
        [39.9590, 116.3696],
        [39.9590, 116.3692],
        [39.9590, 116.3688],
        [39.9590, 116.3684],
        [39.9590, 116.3680],
        // 西侧弯道（从北向南）
        [39.9589, 116.3678],
        [39.9587, 116.3677],
        [39.9585, 116.3677],
        [39.9583, 116.3677],
        [39.9581, 116.3678],
        [39.9580, 116.3680], // 回到起点，开始下一圈
      ];
      int _routeIndex = 0;
      int _interpolationStep = 0;
      const int stepsPerSegment = 8; // 更多插值步 = 更慢更平滑

      _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_routeIndex >= trackRoute.length - 1) {
          _routeIndex = 0; // 自动开始下一圈
        }
        final from = trackRoute[_routeIndex];
        final to = trackRoute[_routeIndex + 1];
        _interpolationStep++;

        double t = _interpolationStep / stepsPerSegment;
        double lat = from[0] + (to[0] - from[0]) * t;
        double lng = from[1] + (to[1] - from[1]) * t;

        // 微小GPS抖动
        lat += (math.Random().nextDouble() - 0.5) * 0.000008;
        lng += (math.Random().nextDouble() - 0.5) * 0.000008;

        if (_interpolationStep >= stepsPerSegment) {
          _interpolationStep = 0;
          _routeIndex++;
        }

        _onLocationUpdate(lat, lng, 5.0);
      });
    }
  }

  void _onLocationUpdate(double lat, double lng, double accuracy) {
    if (accuracy > 25) return;
    LatLng point = LatLng(lat, lng);

    if (_pathPoints.isNotEmpty) {
      double distance = Geolocator.distanceBetween(
        _pathPoints.last.latitude,
        _pathPoints.last.longitude,
        lat,
        lng,
      );

      if (distance > 0 && distance < 100) {
        _totalDistance += distance;
        setState(() {
          _pathPoints.add(point);
        });
        _mapController.move(point, _mapController.camera.zoom);
      }
    } else {
      setState(() {
        _pathPoints.add(point);
      });
      _mapController.move(point, 16.0);
    }
  }

  Future<void> _stopTracking() async {
    _stopwatch.stop();
    _timer?.cancel();
    _simulationTimer?.cancel();
    WakelockPlus.disable();
    await _positionStream?.cancel();
    _positionStream = null;
    if (!_isSimulator) await NotificationService().cancelNotification(999);

    if (_pathPoints.isNotEmpty) {
      final session = ExerciseSession(
        startTime: DateTime.now()
            .subtract(_stopwatch.elapsed)
            .toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        distance: _totalDistance,
        durationSeconds: _stopwatch.elapsed.inSeconds,
        calories: _calories,
        pathPoints: jsonEncode(
          _pathPoints
              .map(
                (e) => {
                  'lat': (e as dynamic).latitude,
                  'lng': (e as dynamic).longitude,
                },
              )
              .toList(),
        ),
        gmtCreate: DateTime.now().toIso8601String(),
      );
      await DBHealthHelper().insertExerciseSession(session);

      // 同时保存为 TrainedDetailLog，这样运动报告页面能展示这条记录
      final now = DateTime.now();
      final startDt = now.subtract(_stopwatch.elapsed);
      final distKm = (_totalDistance / 1000).toStringAsFixed(2);
      final trainLog = TrainedDetailLog(
        trainedDate: DateFormat('yyyy-MM-dd').format(startDt),
        userId: CacheUser.userId,
        groupName: '户外跑步 ${distKm}km',
        groupCategory: '有氧运动',
        groupLevel: '初级',
        trainedStartTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(startDt),
        trainedEndTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
        trainedDuration: _stopwatch.elapsed.inSeconds,
        totolPausedTime: 0,
        totalRestTime: 0,
        consumption: _calories.toInt(),
      );
      await DBTrainingHelper().insertTrainedDetailLog(trainLog);

      // 估算步数并添加到计步器 (跑步约1300步/km)
      final estimatedSteps = (_totalDistance / 1000 * 1300).toInt();
      if (estimatedSteps > 0) {
        await PedometerService().manualAddSteps(estimatedSteps);
      }

      _showSummary(session);
    }

    setState(() {
      _isTracking = false;
    });
  }

  void _showSummary(ExerciseSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('运动总结'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(
              '总距离',
              '${(session.distance / 1000).toStringAsFixed(2)} km',
            ),
            _buildSummaryRow(
              '总耗时',
              _formatDuration(Duration(seconds: session.durationSeconds ?? 0)),
            ),
            _buildSummaryRow(
              '消耗热量',
              '${session.calories?.toStringAsFixed(1)} kcal',
            ),
            _buildSummaryRow('平均配速', _formatPace(_currentPace)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('很好'),
          ),
        ],
      ),
    );
  }

  String _formatPace(double pace) {
    if (pace == 0 || pace.isInfinite) return "--:--";
    int mins = pace.toInt();
    int secs = ((pace - mins) * 60).toInt();
    return "$mins'${secs.toString().padLeft(2, '0')}\"";
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('实时运动追踪')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(39.9585, 116.3690),
              initialZoom: 17.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.freefitness.app',
              ),
              if (_pathPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _pathPoints,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 6,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_pathPoints.isNotEmpty)
                    Marker(
                      point: _pathPoints.last,
                      width: 20.sp,
                      height: 20.sp,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.sp),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Stats Overlay
          Positioned(
            top: 10.sp,
            left: 10.sp,
            right: 10.sp,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.sp),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      '距离 (km)',
                      (_totalDistance / 1000).toStringAsFixed(2),
                    ),
                    _buildStat('用时', _elapsedTimeString),
                    _buildStat('配速', _formatPace(_currentPace)),
                  ],
                ),
              ),
            ),
          ),
          // Simulation Banner
          if (_isSimulator)
            Positioned(
              top: 100.sp,
              left: 50.sp,
              right: 50.sp,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 4.sp,
                  horizontal: 12.sp,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.sp),
                ),
                child: Text(
                  '电脑模拟模式已启用',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
            ),
          // Bottom Controls
          Positioned(
            bottom: 30.sp,
            left: 30.sp,
            right: 30.sp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTracking)
                  Container(
                    margin: EdgeInsets.only(bottom: 10.sp),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.sp,
                      vertical: 8.sp,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.sp),
                    ),
                    child: Text(
                      '消耗热量: ${_calories.toStringAsFixed(1)} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 60.sp,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking
                          ? Colors.redAccent
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.sp),
                      ),
                      elevation: 8,
                    ),
                    onPressed: _toggleTracking,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isTracking ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10.sp),
                        Text(
                          _isTracking ? '停止训练' : '开始追踪',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 4.sp),
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
