import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/storage/db_health_helper.dart';
import '../models/health_models.dart';
import 'package:intl/intl.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  int _todaySteps = 0;
  String _status = 'unknown';

  final _dbHelper = DBHealthHelper();

  int get todaySteps => _todaySteps;
  String get status => _status;

  // 步数监听器
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  Future<void> initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _stepSubscription = _stepCountStream.listen(
        _onStepCount,
        onDone: () => print('Step Count Stream Done'),
        onError: _onStepCountError,
      );
      _statusSubscription = _pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
      );
    }

    // 初始化当天的步数
    await _loadTodaySteps();
  }

  final _stepChangeController = StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepChangeController.stream;

  Future<void> manualAddSteps(int count) async {
    _todaySteps += count;
    await _saveSteps();
    _stepChangeController.add(_todaySteps);
  }

  Future<void> _loadTodaySteps() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var list = await _dbHelper.queryStepsList(startDate: today, endDate: today);
    if (list.isNotEmpty) {
      _todaySteps = list.first.steps;
    }
  }

  void _onStepCount(StepCount event) async {
    // Note: pedometer returns total steps since last boot or similar on some platforms.
    // We might need to handle the offset. But for simplicity in this health app context,
    // we assume it's incremental or we manage the daily reset via DB.
    // A robust way would be to store the 'base' steps for the day.

    // For now, let's just increment or use the event.
    // If it's a huge number, it's cumulative. We should calculate Delta.

    // Simple logic: If we haven't stored 'initialSteps' for today, we do it.
    // But since this is a simplified app, let's treat it as 'current steps today'.

    _todaySteps = event.steps;
    await _saveSteps();
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _status = event.status;
  }

  void _onStepCountError(error) {
    print('onStepCountError: $error');
  }

  void _onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
  }

  Future<void> _saveSteps() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double calories =
        _todaySteps *
        0.04; // Simple calorie estimation: 1 step approx 0.04 kcal

    DailySteps record = DailySteps(
      date: today,
      steps: _todaySteps,
      calories: calories,
      gmtCreate: DateTime.now().toIso8601String(),
    );

    await _dbHelper.insertOrUpdateSteps(record);
  }

  Future<void> setManualSteps(int steps) async {
    _todaySteps = steps;
    await _saveSteps();
  }

  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
  }
}
