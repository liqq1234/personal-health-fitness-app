// ignore_for_file: avoid_print

import 'dart:async';

import '../../models/diary_state.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';

class DBDiaryHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDiaryHelper _dbDiaryHelper = DBDiaryHelper._createInstance();
  factory DBDiaryHelper() => _dbDiaryHelper;

  DBDiaryHelper._createInstance();

  // Stubs for compatibility
  Future<void> deleteDB() async {}
  Future<void> closeDB() async {}

  Future<void> exportDatabase() async {}
  void showTableNameList() {}

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// diary 的相关操作
  ///
  ///
  // 插入单条数据(返回 diary_id)
  Future<int> insertDiary(Diary diary) async {
    try {
      await HttpUtils.post(
        path: ApiEndpoints.diarySync,
        data: diary.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync diary failed: $e");
      return 0;
    }
  }

  Future<List<Object?>> insertDiaryList(List<Diary> diarys) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.diarySync}/batch",
        data: diarys.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync diary failed: $e");
      return [];
    }
  }

  // 修改单条数据
  Future<int> updateDiary(Diary diary) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.diarySync}/${diary.diaryId}",
        data: diary.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update diary failed: $e");
      return 0;
    }
  }

  // 删除单条数据
  Future<int> deleteDiaryById(int id) async {
    try {
      await HttpUtils.delete(
        path: "${ApiEndpoints.diarySync}/$id",
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Delete diary failed: $e");
      return 0;
    }
  }

  // 关键字模糊查询基础活动
  Future<CusDataResult> queryDiaryByKeyword({
    required int userId,
    required String keyword,
    required int pageSize, // 一次查询条数显示
    required int page, // 一次查询的偏移量，用于分页
    // 2023-12-30 指定创建日期升序或者降序排序
    String? dateSort = "desc",
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.diarySync}/search",
        queryParameters: {
          "userId": userId,
          "keyword": keyword,
          "pageSize": pageSize,
          "page": page,
          "dateSort": dateSort,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var resultData = response['data'];
        List<dynamic> list = resultData['list'] ?? [];
        int total = resultData['total'] ?? 0;
        return CusDataResult(
          data: list.map((e) => Diary.fromMap(e)).toList(),
          total: total,
        );
      }
    } catch (e) {
      print("Query diary by keyword failed: $e");
    }
    return CusDataResult(data: [], total: 0);
  }

  // 按日期范围查询(查询某一天也要起止为同一个即可)，查询所有
  Future<List<Diary>> queryDiaryByDateRange(
    int userId, {
    String? startDate,
    String? endDate,
    // 2023-12-30 指定创建日期升序或者降序排序
    String? dateSort = "desc",
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.diarySync}/range",
        queryParameters: {
          "userId": userId,
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
          "dateSort": dateSort,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list.map((e) => Diary.fromMap(e)).toList();
      }
    } catch (e) {
      print("Query diary range failed: $e");
    }
    return [];
  }

  // 按指定编号查询
  Future<List<Diary>> queryDiaryById(int id) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.diarySync}/$id",
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return [Diary.fromMap(response['data'])];
      }
    } catch (e) {
      print("Query diary by id failed: $e");
    }
    return [];
  }
}
