import 'package:intl/intl.dart';
import '../core/dio_client/cus_http_client.dart';
import '../core/storage/db_health_helper.dart';
import '../core/dio_client/api_endpoints.dart';
import '../models/health_models.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _dbHelper = DBHealthHelper();

  // Background sync is no longer needed as all operations are direct to cloud.
  Future<void> syncData() async {
    return;
  }

  // 后端模拟走路并拉取结果
  Future<void> simulateBackendWalk() async {
    try {
      // 请求后端增加模拟步数
      var response = await HttpUtils.post(
        path: "${ApiEndpoints.healthSync}/simulate-walk",
        showLoading: true,
      );

      if (response != null && response['code'] == 200) {
        var data = response['data'];
        DailySteps newSteps = DailySteps(
          date: data['date'],
          steps: data['steps'],
          calories: (data['calories'] as num).toDouble(),
          gmtCreate: data['gmtCreate'],
        );
        // DBHealthHelper now only syncs to cloud, so this essentially re-syncs or confirms.
        await _dbHelper.insertOrUpdateSteps(newSteps);
      }
    } catch (e) {
      print("Simulation failed: $e");
    }
  }

  // 从后端拉取最新步数 (Refreshing data from cloud)
  Future<void> pullSteps() async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // DBHealthHelper path for query already goes to cloud.
      await _dbHelper.queryStepsList(startDate: today, endDate: today);
    } catch (e) {
      print("Pull failed: $e");
    }
  }
}
