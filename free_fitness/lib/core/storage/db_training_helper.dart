import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/training_state.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';
import 'ddl_training.dart';

class DBTrainingHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBTrainingHelper _dbHelper = DBTrainingHelper._createInstance();
  // 构造函数，返回单例
  factory DBTrainingHelper() => _dbHelper;

  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBTrainingHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取存储数据库的目录路径
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path, TrainingDdl.databaseName);

    if (kDebugMode) {
      print("初始化 TRAINING sqlite数据库存放的地址：$path");
    }

    // 在给定路径上打开/创建数据库
    var trainingDb = await openDatabase(path, version: 1, onCreate: createDB);
    dbFilePath = path;
    return trainingDb;
  }

  // 创建训练数据库相关表
  // 创建训练数据库相关表 (Decommissioned)
  void createDB(Database db, int newVersion) async {
    print("开始创建表 _createDb (Training moved to cloud)……");
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    if (kDebugMode) {
      print("training db isOpen ${db.isOpen}");
    }
    await db.close();
    if (kDebugMode) {
      print("training db isOpen ${db.isOpen}");
    }

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    if (kDebugMode) {
      print("开始删除內嵌的sqlite db文件，db文件地址：$dbFilePath");
    }

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dbFilePath);

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;
  }

  // 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    )).map((row) => row['name'] as String).toList(growable: false);

    if (kDebugMode) {
      print("TrainingDB中拥有的表名:------------");
      print(tableNames);
    }
  }

  // 导出所有数据
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(p.join(appDocDir.path, "db_export")).create();

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    // 遍历所有表
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'];
      // 不是自建的表，不导出
      if (!tableName.startsWith("ff_")) {
        continue;
      }

      String tempFilePath = p.join(tempDir.path, '$tableName.json');

      // 查询表中所有数据
      List<Map<String, dynamic>> result = await db.query(tableName);

      // 将结果转换为JSON字符串
      String jsonStr = jsonEncode(result);

      // 创建临时导出文件
      File tempFile = File(tempFilePath);

      // 将JSON字符串写入临时文件
      await tempFile.writeAsString(jsonStr);
    }
  }

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// 动作库基础表 exercise 的相关操作
  ///

  // 插入单条数据(返回exercise_id) (Decommissioned/Redirected)
  Future<int> insertExercise2(Exercise exercise) async =>
      insertExercise(exercise);

  // 插入单条基础活动 (Cloud)
  Future<int> insertExercise(Exercise exercise) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/exercises",
        data: exercise.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync exercise failed: $e");
      return 0;
    }
  }

  // 理论上插入时数据重复，是直接替换，但主键不能变，上面那个主键会变化，所以手动处理
  // 插入基础活动列表 (Cloud)
  Future<void> insertExerciseList(List<Exercise> exercises) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/exercises/batch",
        data: exercises.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
    } catch (e) {
      print("Batch sync exercises failed: $e");
    }
  }

  // 修改单条数据
  // 修改单条基础活动 (Cloud)
  Future<int> updateExercise(Exercise exercise) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.trainingSync}/exercises/${exercise.exerciseId}",
        data: exercise.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update exercise failed: $e");
      return 0;
    }
  }

  // 删除单条数据
  // 删除单条基础活动 (Cloud)
  Future<int> deleteExerciseById(int id) async {
    try {
      await HttpUtils.delete(
        path: "${ApiEndpoints.trainingSync}/exercises/$id",
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Delete exercise failed: $e");
      return 0;
    }
  }

  // 通过编号查询单条数据 (Cloud)
  Future<Exercise> queryExerciseById(int id) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/exercises/$id",
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return Exercise.fromMap(response['data']);
      }
    } catch (e) {
      print("Query exercise by id failed: $e");
    }
    throw Exception("Exercise not found");
  }

  // 关键字模糊查询基础活动 (Cloud)
  Future<CusDataResult> queryExerciseByKeyword({
    required String keyword,
    required int pageSize, // 一次查询条数显示
    required int page, // 一次查询的偏移量，用于分页
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/exercises/search",
        queryParameters: {
          "keyword": keyword,
          "pageSize": pageSize,
          "page": page > 0 ? page - 1 : 0,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var data = response['data'] as Map<String, dynamic>;
        var list = (data['list'] ?? data['content'] ?? []) as List;
        return CusDataResult(
          data: list.map((e) => Exercise.fromMap(e)).toList(),
          total: data['total'] ?? data['totalElements'] ?? 0,
        );
      }
    } catch (e) {
      print("Query exercise by keyword failed: $e");
    }
    return CusDataResult(data: [], total: 0);
  }

  // 指定栏位查询基础运动 (Cloud)
  Future<CusDataResult> queryExercise({
    int? exerciseId,
    String? exerciseCode,
    String? exerciseName,
    String? force,
    String? level,
    String? mechanic,
    String? equipment,
    String? category,
    String? primaryMuscle, // 都只有单个
    required int pageSize, // 一次查询条数显示
    required int page, // 页码，用于分页
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/exercises",
        queryParameters: {
          if (exerciseId != null) "exerciseId": exerciseId,
          if (exerciseCode != null) "exerciseCode": exerciseCode,
          if (exerciseName != null) "exerciseName": exerciseName,
          if (force != null) "force": force,
          if (level != null) "level": level,
          if (mechanic != null) "mechanic": mechanic,
          if (equipment != null) "equipment": equipment,
          if (category != null) "category": category,
          if (primaryMuscle != null) "primaryMuscle": primaryMuscle,
          "pageSize": pageSize,
          "page": page > 0 ? page - 1 : 0,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var data = response['data'] as Map<String, dynamic>;
        var list = (data['list'] ?? data['content'] ?? []) as List;
        return CusDataResult(
          data: list.map((e) => Exercise.fromMap(e)).toList(),
          total: data['total'] ?? data['totalElements'] ?? 0,
        );
      }
    } catch (e) {
      print("Query exercise failed: $e");
    }
    return CusDataResult(data: [], total: 0);
  }

  ///***********************************************/
  ///   group and action 的相关操作
  ///

  // 插入单条训练 (Cloud)
  Future<int> insertTrainingGroup(TrainingGroup group) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/groups",
        data: group.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync group failed: $e");
      return 0;
    }
  }

  // 插入单条训练组列表 (Cloud)
  Future<List<Object?>> insertTrainingGroupList(
    List<TrainingGroup> tgList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/groups/batch",
        data: tgList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync groups failed: $e");
      return [];
    }
  }

  // 修改指定训练基本信息 (Cloud)
  Future<int> updateTrainingGroup(int groupId, TrainingGroup group) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.trainingSync}/groups/$groupId",
        data: group.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update group failed: $e");
      return 0;
    }
  }

  // 删除单条训练 (Cloud)
  Future<dynamic> deleteGroupById(int groupId) async {
    try {
      return await HttpUtils.delete(
        path: "${ApiEndpoints.trainingSync}/groups/$groupId",
        showLoading: false,
      );
    } catch (e) {
      throw Exception("删除指定训练及其动作失败: $e");
    }
  }

  // 删除单条计划 (Cloud)
  Future<dynamic> deletePlanById(int planId) async {
    try {
      return await HttpUtils.delete(
        path: "${ApiEndpoints.trainingSync}/plans/$planId",
        showLoading: false,
      );
    } catch (e) {
      throw Exception("删除指定计划及其训练组失败: $e");
    }
  }

  // 查询指定训练以及其所有动作 (Cloud)
  Future<List<GroupWithActions>> searchGroupWithActions({
    int? groupId,
    String? groupName, // 模糊查询
    String? groupCategory, // 分类和级别最好是下拉选择的结果，用精确查询
    String? groupLevel,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/groups/search",
        queryParameters: {
          if (groupId != null) "groupId": groupId,
          if (groupName != null) "groupName": groupName,
          if (groupCategory != null) "groupCategory": groupCategory,
          if (groupLevel != null) "groupLevel": groupLevel,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list
            .map(
              (e) => GroupWithActions(
                group: TrainingGroup.fromMap(e['group']),
                actionDetailList: (e['actions'] as List)
                    .map(
                      (a) => ActionDetail(
                        action: TrainingAction.fromMap(a['action']),
                        exercise: Exercise.fromMap(a['exercise']),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
      }
    } catch (e) {
      print("Search group with actions failed: $e");
    }
    return [];
  }

  // 插入动作组 (Cloud)
  Future<List<Object?>> insertTrainingActionList(
    List<TrainingAction> actionList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/actions/batch",
        data: actionList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync actions failed: $e");
      return [];
    }
  }

  // 更新指定训练的所有动作 (Cloud)
  Future<List<Object?>> renewGroupWithActionsList(
    int groupId,
    List<TrainingAction> actionList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/groups/$groupId/actions/renew",
        data: actionList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Renew group actions failed: $e");
      return [];
    }
  }

  ///***********************************************/
  ///   plan and group 的相关操作
  ///

  // 插入单个计划基本信息 (Cloud)
  Future<int> insertTrainingPlan(TrainingPlan plan) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/plans",
        data: plan.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync plan failed: $e");
      return 0;
    }
  }

  // 插入训练计划列表 (Cloud)
  Future<List<Object?>> insertTrainingPlanList(
    List<TrainingPlan> tpList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/plans/batch",
        data: tpList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync plans failed: $e");
      return [];
    }
  }

  // 插入计划组列表 (Cloud)
  Future<List<Object?>> insertPlanHasGroupList(
    List<PlanHasGroup> phgList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/plans/groups/batch",
        data: phgList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync plan groups failed: $e");
      return [];
    }
  }

  // 修改指定计划基本信息 (Cloud)
  Future<int> updateTrainingPlanById(int planId, TrainingPlan plan) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.trainingSync}/plans/$planId",
        data: plan.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update plan failed: $e");
      return 0;
    }
  }

  Future<List<TrainingPlan>> queryTrainingPlanById(int planId) async {
    return (await (await database).query(
      TrainingDdl.tableNameOfPlan,
      where: "plan_id =? ",
      whereArgs: [planId],
    )).map((row) => TrainingPlan.fromMap(row)).toList();
  }

  // Deduplicate existing exercises (Decommissioned/Dummy for compatibility)
  Future<int> deduplicateExercises() async => 0;

  // 查询指定计划以及其所有训练 (Cloud)
  Future<List<PlanWithGroups>> searchPlanWithGroups({
    int? planId,
    String? planName, // 模糊查询
    String? planCode, // 模糊查询
    String? planCategory, // 分类和级别最好是下拉选择的结果，用精确查询
    String? planLevel,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/plans/search",
        queryParameters: {
          if (planId != null) "planId": planId,
          if (planName != null) "planName": planName,
          if (planCode != null) "planCode": planCode,
          if (planCategory != null) "planCategory": planCategory,
          if (planLevel != null) "planLevel": planLevel,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list
            .map(
              (e) => PlanWithGroups(
                plan: TrainingPlan.fromMap(e['plan']),
                groupDetailList: (e['groups'] as List)
                    .map(
                      (g) => GroupWithActions(
                        group: TrainingGroup.fromMap(g['group']),
                        actionDetailList: (g['actions'] as List)
                            .map(
                              (a) => ActionDetail(
                                action: TrainingAction.fromMap(a['action']),
                                exercise: Exercise.fromMap(a['exercise']),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
      }
    } catch (e) {
      print("Search plan with groups failed: $e");
    }
    return [];
  }

  // 更新指定训练的所有动作(删除所有已有的，新增传入的)
  // 更新指定计划的所有计划项 (Cloud)
  Future<List<Object?>> renewPlanWithGroupList(
    int planId,
    List<PlanHasGroup> phgList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/plans/$planId/groups/renew",
        data: phgList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Renew plan groups failed: $e");
      return [];
    }
  }

  ///***********************************************/
  ///  training_detail_log 的相关操作
  ///

  // 插入单条训练日志 (Cloud)
  Future<int> insertTrainedDetailLog(TrainedDetailLog log) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/logs",
        data: log.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync training log failed: $e");
      return 0;
    }
  }

  // 批量插入训练日志 (Cloud)
  Future<List<Object?>> insertTrainingDetailLogList(
    List<TrainedDetailLog> tlList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.trainingSync}/logs/batch",
        data: tlList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync logs failed: $e");
      return [];
    }
  }

  // 2023-12-27 日志改为宽表，直接查出数据，不用关联查询
  // 2023-12-27 日志改为宽表，直接查出数据，不用关联查询 (Cloud)
  Future<List<TrainedDetailLog>> queryTrainedDetailLog({
    int? userId,
    String? startDate,
    String? endDate,
    String? gmtCreateSort = "ASC", // 按创建时间升序或者降序排序
  }) async {
    try {
      bool isRange = startDate != null && endDate != null;
      var response = await HttpUtils.get(
        path: isRange
            ? "${ApiEndpoints.trainingSync}/logs/range"
            : "${ApiEndpoints.trainingSync}/logs",
        queryParameters: {
          "userId": userId ?? CacheUser.userId,
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
          if (!isRange) "page": 0,
          if (!isRange) "size": 1000,
          "gmtCreateSort": gmtCreateSort,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var data = response['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('content')) {
          list = data['content'] as List;
        } else if (data is Map && data.containsKey('list')) {
          list = data['list'] as List;
        }
        return list.map((e) => TrainedDetailLog.fromMap(e)).toList();
      }
    } catch (e) {
      print("Query training logs failed: $e");
    }
    return [];
  }

  /// 2023-12-27 查询训练计划中每一个训练日最近一次跟练的时间
  /// 因为group_name和plan_name是唯一的，而id是自增，可能删除之后万一新的又和旧的编号一样了
  /// 所以通过名称查询；而且这个名称也不会是用户手动输入，所以也不担心匹配不上。
  // 查询指定计划中每一个训练日最近一次跟练的时间 (Cloud)
  Future<Map<int, TrainedDetailLog?>> queryLastTrainingDetailLogByPlanName(
    TrainingPlan plan,
  ) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/logs/last-by-plan",
        queryParameters: {"planName": plan.planName},
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is Map) {
        Map<String, dynamic> data = response['data'];
        return data.map(
          (key, value) => MapEntry(
            int.parse(key),
            value != null ? TrainedDetailLog.fromMap(value) : null,
          ),
        );
      }
    } catch (e) {
      print("Query last log by plan failed: $e");
    }
    return {};
  }

  /// 2023-12-27 因为已经有了训练日志宽表，所以，即便有训练日志也可以删除；
  /// 因此判断是否被使用排除掉存在于日志表这一条；也就是说:
  ///   计划可以随便删；
  ///   训练没有被计划使用即可删除；
  ///   exercise没有对应action(没有被训练使用)即可删除
  // 判断基础活动是否被使用 (Cloud)
  Future<List<Map<String, Object?>>> isExerciseUsed(int exerciseId) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/exercises/$exerciseId/usage",
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list.cast<Map<String, Object?>>();
      }
    } catch (e) {
      print("Check exercise usage failed: $e");
    }
    return [];
  }

  // 判断训练组是否被使用 (Cloud)
  Future<List<Map<String, Object?>>> isGroupUsed(int groupId) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.trainingSync}/groups/$groupId/usage",
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list.cast<Map<String, Object?>>();
      }
    } catch (e) {
      print("Check group usage failed: $e");
    }
    return [];
  }
}
