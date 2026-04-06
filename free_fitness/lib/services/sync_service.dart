import 'package:intl/intl.dart';
import '../core/dio_client/cus_http_client.dart';
import '../core/storage/db_health_helper.dart';
import '../core/constants/constants.dart';
import '../core/dio_client/api_endpoints.dart';
import '../models/health_models.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _dbHelper = DBHealthHelper();

  Future<void> syncData() async {
    try {
      int currentUserId = CacheUser.userId;

      // 1. Fetch data from DB
      var steps = await _dbHelper.queryStepsList();
      var sleep = await _dbHelper.querySleepList();
      var diet = await _dbHelper.queryDietList();

      // 2. Prepare payload
      Map<String, dynamic> payload = {
        "userId": currentUserId,
        "steps": steps
            .map(
              (e) => {
                "stepsId": e.id,
                "date": e.date,
                "steps": e.steps,
                "calories": e.calories,
                "gmtCreate": e.gmtCreate,
              },
            )
            .toList(),
        "sleep": sleep
            .map(
              (e) => {
                "sleepId": e.id,
                "startTime": e.startTime,
                "endTime": e.endTime,
                "durationHours": e.durationHours,
                "note": e.note,
                "gmtCreate": e.gmtCreate,
              },
            )
            .toList(),
        "diet": diet
            .map(
              (e) => {
                "dietId": e.id,
                "date": e.date,
                "category": e.category,
                "foodName": e.foodName,
                "calories": e.calories,
                "protein": e.protein,
                "gmtCreate": e.gmtCreate,
              },
            )
            .toList(),
        "timestamp": DateTime.now().toIso8601String(),
      };

      // 3. Post to Spring Boot
      await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/sync",
        data: payload,
        showLoading: false,
      );

      print("Background Sync successful!");
    } catch (e) {
      print("Background Sync failed: $e");
    }
  }

  // 4. 后端模拟走路并拉取结果
  Future<void> simulateBackendWalk() async {
    try {
      // 请求后端增加模拟步数
      var response = await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/simulate-walk",
        showLoading: true,
      );

      if (response != null && response['code'] == 200) {
        var data = response['data'];
        // 将后端模拟得到的新步数更新到本地数据库
        DailySteps newSteps = DailySteps(
          date: data['date'],
          steps: data['steps'],
          calories: (data['calories'] as num).toDouble(),
          gmtCreate: data['gmtCreate'],
        );
        await _dbHelper.insertOrUpdateSteps(newSteps);
      }
    } catch (e) {
      print("Simulation failed: $e");
    }
  }

  // 5. 从后端拉取最新步数
  Future<void> pullSteps() async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.healthSync}/steps",
        queryParameters: {"startDate": today, "endDate": today},
        showLoading: false,
      );

      if (response != null &&
          response['code'] == 200 &&
          response['data'] != null) {
        List<dynamic> list = response['data'];
        for (var item in list) {
          DailySteps s = DailySteps(
            date: item['date'],
            steps: item['steps'],
            calories: (item['calories'] as num).toDouble(),
            gmtCreate: item['gmtCreate'],
          );
          await _dbHelper.insertOrUpdateSteps(s);
        }
      }
    } catch (e) {
      print("Pull failed: $e");
    }
  }
}
