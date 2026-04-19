import 'dart:async';

import '../../models/user_state.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';

class DBUserHelper {
  // 单例模式
  static final DBUserHelper _dbHelper = DBUserHelper._createInstance();
  factory DBUserHelper() => _dbHelper;

  DBUserHelper._createInstance();

  // Stubs for compatibility
  Future<void> deleteDB() async {}
  Future<void> closeDB() async {}

  Future<void> exportDatabase() async {}
  void showTableNameList() {}

  ///
  ///  Helper 的相关方法 (Cloud Only for User)
  ///

  // 查询用户 (Only from Cloud)
  Future<User?> queryUser({int? userId}) async {
    if (userId == null) return null;
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.userProfile}/$userId",
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return User.fromMap(response['data']);
      }
    } catch (e) {
      print("Cloud queryUser failed: $e");
    }
    return null;
  }

  // 查询用户列表 (Currently not fully supported by backend for 'all users', returning current only)
  Future<List<User>?> queryUserList() async {
    var user = await queryUser(userId: CacheUser.userId);
    return user != null ? [user] : [];
  }

  // 修改单条 user (Only to Cloud)
  Future<int> updateUser(User user) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.userUpdate}/${user.userId}",
        data: {
          "userName": user.userName,
          "gender": user.gender,
          "avatar": user.avatar,
          "dateOfBirth": user.dateOfBirth,
          "height": user.height,
          "heightUnit": user.heightUnit,
          "currentWeight": user.currentWeight,
          "targetWeight": user.targetWeight,
          "weightUnit": user.weightUnit,
          "description": user.description,
          "rdaGoal": user.rdaGoal,
          "proteinGoal": user.proteinGoal,
          "fatGoal": user.fatGoal,
          "choGoal": user.choGoal,
          "actionRestTime": user.actionRestTime,
        },
        showLoading: false,
      );
      return 1; // Success
    } catch (e) {
      print("Sync User failed: $e");
      return 0; // Fail
    }
  }

  // 批量插入用户 (Safe to remove as primary logic, but keeping empty signature to avoid errors)
  Future<List<Object?>> insertUserList(List<User> userList) async {
    return [];
  }

  ///***********************************************/

  Future<List<Object?>> insertIntakeDailyGoalList(
    List<IntakeDailyGoal> goals,
  ) async {
    // 同步到后端 (Sync to backend)
    try {
      if (goals.isNotEmpty) {
        await HttpUtils.put(
          path: "${ApiEndpoints.intakeGoals}/${goals[0].userId}/intake-goals",
          data: goals.map((e) => e.toJson()).toList(),
          showLoading: false,
        );
      }
    } catch (e) {
      print("Sync intake goals failed: $e");
    }
    return [];
  }

  // 查询用户带上每周具体摄入目标
  // 这里查询的都是当前app的唯一用户，就一个用户
  Future<UserWithIntakeDailyGoal> queryUserWithIntakeDailyGoal({
    required int userId,
  }) async {
    User? user;
    List<IntakeDailyGoal> goals = [];

    // 1. 从云端获取用户信息 (Fetch User)
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.userProfile}/$userId",
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        user = User.fromMap(response['data']);
      }
    } catch (e) {
      print("Fetch user for goal display failed: $e");
    }

    if (user == null) {
      throw Exception("无法获取用户信息，请检查网络连接");
    }

    // 2. 从云端获取饮食目标 (Fetch Goals)
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.intakeGoals}/$userId/intake-goals",
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        goals = (response['data'] as List)
            .map((row) => IntakeDailyGoal.fromMap(row))
            .toList();
      }
    } catch (e) {
      print("Fetch intake goals failed: $e");
    }

    return UserWithIntakeDailyGoal(intakeGoals: goals, user: user);
  }

  // 修改用户的周摄入宏量素目标 (Cloud Only)
  Future<int> updateIntakeDailyGoalByUser(List<IntakeDailyGoal> goals) async {
    try {
      if (goals.isNotEmpty) {
        await HttpUtils.put(
          path: "${ApiEndpoints.intakeGoals}/${goals[0].userId}/intake-goals",
          data: goals.map((e) => e.toJson()).toList(),
          showLoading: false,
        );
        return 1;
      }
    } catch (e) {
      print("Sync intake goals failed: $e");
    }
    return 0;
  }

  ///***********************************************/
  /// weight_trent 的相关操作
  ///

  // 批量插入体重趋势数据(有单条的，也放到list)
  Future<List<Object?>> insertWeightTrendList(
    List<WeightTrend> weightTrendList,
  ) async {
    // 同步到后端 (Sync to backend)
    try {
      for (var item in weightTrendList) {
        await HttpUtils.post(
          path: "${ApiEndpoints.weightTrends}/${item.userId}/weight-trends",
          data: item.toJson(),
          showLoading: false,
        );
      }
    } catch (e) {
      print("Sync weight trends failed: $e");
    }
    return [];
  }

  // 批量删除体重趋势数据 (Cloud Only)
  Future<List<Object?>> deleteWeightTrendList(
    List<WeightTrend> weightTrendList,
  ) async {
    try {
      for (var item in weightTrendList) {
        await HttpUtils.delete(
          path:
              "${ApiEndpoints.weightTrends}/${item.userId}/weight-trends/${item.weightTrendId}",
          showLoading: false,
        );
      }
    } catch (e) {
      print("Delete weight trends failed: $e");
    }
    return [];
  }

  // 查询用户体重数据 (Cloud Only)
  Future<List<WeightTrend>> queryWeightTrendByUser({
    int? userId,
    String? startDate,
    String? endDate,
    String? gmtCreateSort = "ASC",
  }) async {
    if (userId == null) return [];

    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.weightTrends}/$userId/weight-trends",
        queryParameters: {
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
          "sort": gmtCreateSort,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        return (response['data'] as List)
            .map((row) => WeightTrend.fromMap(row))
            .toList();
      }
    } catch (e) {
      print("Query weight trends failed: $e");
    }
    return [];
  }
}
