import 'dart:async';
import 'package:intl/intl.dart';
import '../../models/health_models.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';

class DBHealthHelper {
  // 单例模式
  static final DBHealthHelper _dbHelper = DBHealthHelper._createInstance();
  factory DBHealthHelper() => _dbHelper;

  DBHealthHelper._createInstance();

  // Stubs for compatibility
  Future<void> deleteDB() async {}
  Future<void> closeDB() async {}
  Future<void> exportDatabase() async {}
  void showTableNameList() {}

  ///***********************************************/
  /// 步数相关操作
  ///

  Future<int> insertOrUpdateSteps(DailySteps steps) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/steps",
        data: steps.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync steps failed: $e");
      return 0;
    }
  }

  Future<List<DailySteps>> queryStepsList({
    String? startDate,
    String? endDate,
  }) async {
    if (startDate != null && endDate != null) {
      try {
        var response = await HttpUtils.get(
          path: "${ApiEndpoints.healthSync}/steps",
          queryParameters: {
            "userId": CacheUser.userId,
            "startDate": startDate,
            "endDate": endDate,
          },
          showLoading: false,
        );
        if (response != null &&
            response['data'] != null &&
            response['data'] is List) {
          return (response['data'] as List)
              .map((e) => DailySteps.fromMap(e))
              .toList();
        }
      } catch (e) {
        print("Query steps from cloud failed: $e");
      }
    }
    return [];
  }

  ///***********************************************/
  /// 睡眠相关操作
  ///

  Future<int> insertSleep(SleepRecord record) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/sleeps",
        data: record.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync sleep failed: $e");
      return 0;
    }
  }

  Future<List<SleepRecord>> querySleepList({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.healthSync}/sleeps",
        queryParameters: {"limit": limit, "userId": CacheUser.userId},
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        return (response['data'] as List)
            .map((e) => SleepRecord.fromMap(e))
            .toList();
      }
    } catch (e) {
      print("Query sleep from cloud failed: $e");
    }
    return [];
  }

  ///***********************************************/
  /// 饮食相关操作
  ///

  Future<int> insertDiet(DietLog log) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/diet-logs",
        data: log.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync diet failed: $e");
      return 0;
    }
  }

  Future<List<DietLog>> queryDietList({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    String? targetDate = date ?? startDate;

    if (targetDate != null) {
      try {
        var response = await HttpUtils.get(
          path: "${ApiEndpoints.healthSync}/diet-logs",
          queryParameters: {"date": targetDate, "userId": CacheUser.userId},
          showLoading: false,
        );
        if (response != null &&
            response['data'] != null &&
            response['data'] is List) {
          return (response['data'] as List)
              .map((e) => DietLog.fromMap(e))
              .toList();
        }
      } catch (e) {
        print("Query diet from cloud failed: $e");
      }
    }
    return [];
  }

  ///***********************************************/
  /// 运动会话相关操作
  ///

  Future<int> insertExerciseSession(ExerciseSession session) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/exercise-sessions",
        data: session.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync exercise session failed: $e");
      return 0;
    }
  }

  Future<List<ExerciseSession>> queryExerciseSessions() async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.healthSync}/exercise-sessions",
        queryParameters: {"userId": CacheUser.userId},
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        return (response['data'] as List)
            .map((e) => ExerciseSession.fromMap(e))
            .toList();
      }
    } catch (e) {
      print("Query exercise sessions failed: $e");
    }
    return [];
  }

  /// AI 模糊识别饮食文本
  Future<dynamic> parseAiText(String text) async {
    try {
      var response = await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/parse-ai",
        data: text,
        showLoading: true,
      );
      return response;
    } catch (e) {
      print("AI parse failed: $e");
      return null;
    }
  }

  /// 获取当日营养分析与建议
  Future<dynamic> getNutritionAnalysis({String? date}) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/analysis",
        queryParameters: {
          "date": date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "userId": CacheUser.userId,
        },
        showLoading: true,
      );
      return response;
    } catch (e) {
      print("Get analysis failed: $e");
      return null;
    }
  }

  /// 获取运动分析与AI建议
  Future<dynamic> getExerciseAnalysis({bool force = false}) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.healthSync}/exercise/analysis",
        queryParameters: {"userId": CacheUser.userId, "force": force},
        showLoading: false, // UI 已有局部 loading，此处不再重复显示全局 loading
      );
      return response;
    } catch (e) {
      print("Get exercise analysis failed: $e");
      return null;
    }
  }

  /// 获取睡眠分析与AI建议
  Future<dynamic> getSleepAnalysis({bool force = false}) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.healthSync}/sleep/analysis",
        queryParameters: {"userId": CacheUser.userId, "force": force},
        showLoading: false, // UI 已有局部 loading
      );
      return response;
    } catch (e) {
      print("Get sleep analysis failed: $e");
      return null;
    }
  }
}
