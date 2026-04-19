import '../dio_client/cus_http_client.dart';
import '../constants/constants.dart';
import '../../models/health_models.dart';

class DBSleepHelper {
  static final DBSleepHelper _instance = DBSleepHelper._internal();
  factory DBSleepHelper() => _instance;
  DBSleepHelper._internal();

  Future<int> insertSleepRecord(SleepRecord record) async {
    try {
      await HttpUtils.post(
        path: "/api/v1/health/sleep",
        data: record.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync sleep record failed: $e");
      return 0;
    }
  }

  Future<List<SleepRecord>> querySleepRecords({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await HttpUtils.get(
        path: "/api/v1/health/sleep",
        queryParameters: {
          "userId": CacheUser.userId,
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        List<dynamic> list = response['data'];
        return list.map((e) => SleepRecord.fromMap(e)).toList();
      }
    } catch (e) {
      print("Query sleep records failed: $e");
    }
    return [];
  }

  Future<int> deleteSleepRecord(int id) async {
    try {
      await HttpUtils.delete(
        path: "/api/v1/health/sleep/$id",
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Delete sleep record failed: $e");
      return 0;
    }
  }
}
