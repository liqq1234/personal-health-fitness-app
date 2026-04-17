import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/health_models.dart';
import 'ddl_health_core.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';

class DBHealthHelper {
  // 单例模式
  static final DBHealthHelper _dbHelper = DBHealthHelper._createInstance();
  factory DBHealthHelper() => _dbHelper;
  static Database? _database;

  var healthDbFilePath = "";

  DBHealthHelper._createInstance();

  Future<Database> get database async => _database ??= await initializeDB();

  Future<Database> initializeDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path, HealthCoreDdl.databaseName);

    var healthDb = await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
    healthDbFilePath = path;
    return healthDb;
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(HealthCoreDdl.ddlSteps);
      await db.execute(HealthCoreDdl.ddlSleep);
      await db.execute(HealthCoreDdl.ddlDiet);
      await db.execute(HealthCoreDdl.ddlExerciseSession);
    }
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(HealthCoreDdl.ddlSteps);
    await db.execute(HealthCoreDdl.ddlSleep);
    await db.execute(HealthCoreDdl.ddlDiet);
    await db.execute(HealthCoreDdl.ddlExerciseSession);
  }

  ///***********************************************/
  /// 步数相关操作
  ///

  Future<int> insertOrUpdateSteps(DailySteps steps) async {
    // 1. 先保存并更新到本地数据库
    Database db = await database;
    await db.insert(
      HealthCoreDdl.tableNameSteps,
      steps.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. 异步同步到云端
    if (isCloudSyncEnabled) {
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
    return 1;
  }

  Future<List<DailySteps>> queryStepsList({
    String? startDate,
    String? endDate,
  }) async {
    // 1. 优先查询本地数据库
    Database db = await database;
    String whereClause = "";
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = "date BETWEEN ? AND ?";
      whereArgs = [startDate, endDate];
    } else if (startDate != null) {
      whereClause = "date >= ?";
      whereArgs = [startDate];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameSteps,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: "date DESC",
    );

    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) {
        return DailySteps.fromMap(maps[i]);
      });
    }

    // 2. 如果本地没有（比如新安装），则尝试从云端拉取 (仅当提供了日期范围时)
    if (isCloudSyncEnabled && startDate != null && endDate != null) {
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
          var cloudList = (response['data'] as List)
              .map((e) => DailySteps.fromMap(e))
              .toList();
          // 如果云端有数据，存入本地一份
          for (var s in cloudList) {
            await db.insert(
              HealthCoreDdl.tableNameSteps,
              s.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return cloudList;
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
    // 1. 先保存并更新到本地数据库
    Database db = await database;
    await db.insert(
      HealthCoreDdl.tableNameSleep,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. 异步同步到云端
    if (isCloudSyncEnabled) {
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
    return 1;
  }

  Future<List<SleepRecord>> querySleepList({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    // 1. 优先查询本地数据库
    Database db = await database;

    String whereClause = "";
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = "start_time BETWEEN ? AND ?";
      whereArgs = ["$startDate 00:00:00", "$endDate 23:59:59"];
    } else if (startDate != null) {
      whereClause = "start_time >= ?";
      whereArgs = ["$startDate 00:00:00"];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameSleep,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      limit: limit,
      orderBy: "start_time DESC",
    );

    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) {
        return SleepRecord.fromMap(maps[i]);
      });
    }

    // 2. 如果本地没有，则尝试从云端拉取
    if (isCloudSyncEnabled) {
      try {
        var response = await HttpUtils.get(
          path: "${ApiEndpoints.healthSync}/sleeps",
          queryParameters: {"limit": limit, "userId": CacheUser.userId},
          showLoading: false,
        );
        if (response != null &&
            response['data'] != null &&
            response['data'] is List) {
          var cloudList = (response['data'] as List)
              .map((e) => SleepRecord.fromMap(e))
              .toList();
          for (var s in cloudList) {
            await db.insert(
              HealthCoreDdl.tableNameSleep,
              s.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return cloudList;
        }
      } catch (e) {
        print("Query sleep from cloud failed: $e");
      }
    }
    return [];
  }

  ///***********************************************/
  /// 饮食相关操作
  ///

  Future<int> insertDiet(DietLog log) async {
    // 1. 本地存储
    Database db = await database;
    await db.insert(
      HealthCoreDdl.tableNameDiet,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. 云端同步
    if (isCloudSyncEnabled) {
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
    return 1;
  }

  Future<List<DietLog>> queryDietList({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    // 1. 本地查找
    Database db = await database;
    String whereClause = "";
    List<dynamic> whereArgs = [];

    if (date != null) {
      whereClause = "date = ?";
      whereArgs = [date];
    } else if (startDate != null && endDate != null) {
      whereClause = "date BETWEEN ? AND ?";
      whereArgs = [startDate, endDate];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameDiet,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: "gmt_create DESC",
    );

    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) {
        return DietLog.fromMap(maps[i]);
      });
    }

    // 2. 云端查找 (仅当提供 date 时)
    if (isCloudSyncEnabled && date != null) {
      try {
        var response = await HttpUtils.get(
          path: "${ApiEndpoints.healthSync}/diet-logs",
          queryParameters: {"date": date, "userId": CacheUser.userId},
          showLoading: false,
        );
        if (response != null &&
            response['data'] != null &&
            response['data'] is List) {
          var list = (response['data'] as List)
              .map((e) => DietLog.fromMap(e))
              .toList();
          for (var item in list) {
            await db.insert(
              HealthCoreDdl.tableNameDiet,
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return list;
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
    if (isCloudSyncEnabled) {
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
    return 1;
  }

  Future<List<ExerciseSession>> queryExerciseSessions() async {
    if (isCloudSyncEnabled) {
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
    }
    return [];
  }
}
