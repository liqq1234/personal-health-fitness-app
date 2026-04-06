import '../core/dio_client/cus_http_client.dart';
import '../models/training_state.dart';

class TrainingScheduleService {
  static const String basePlanPath = '/training/schedules';

  /// 获取用户的所有排程
  static Future<List<TrainingSchedule>> getAllSchedules(int userId) async {
    final response = await HttpUtils.get(path: '$basePlanPath/user/$userId');
    if (response is List) {
      return response.map((item) => TrainingSchedule.fromMap(item)).toList();
    }
    return [];
  }

  /// 获取用户某一天的排程
  static Future<List<TrainingSchedule>> getDailySchedules(
    int userId,
    String date,
  ) async {
    final response = await HttpUtils.get(
      path: '$basePlanPath/user/$userId/daily',
      queryParameters: {'date': date},
    );
    if (response is List) {
      return response.map((item) => TrainingSchedule.fromMap(item)).toList();
    }
    return [];
  }

  /// 创建排程
  static Future<TrainingSchedule?> createSchedule(
    TrainingSchedule schedule,
  ) async {
    final response = await HttpUtils.post(
      path: basePlanPath,
      data: schedule.toJson(),
    );
    if (response != null && response is Map<String, dynamic>) {
      return TrainingSchedule.fromMap(response);
    }
    return null;
  }

  /// 更新排程
  static Future<TrainingSchedule?> updateSchedule(
    int id,
    TrainingSchedule schedule,
  ) async {
    final response = await HttpUtils.put(
      path: '$basePlanPath/$id',
      data: schedule.toJson(),
    );
    if (response != null && response is Map<String, dynamic>) {
      return TrainingSchedule.fromMap(response);
    }
    return null;
  }

  /// 删除排程
  static Future<bool> deleteSchedule(int id) async {
    try {
      await HttpUtils.delete(path: '$basePlanPath/$id');
      return true;
    } catch (e) {
      return false;
    }
  }
}
