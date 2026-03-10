import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/health_models.dart';
import 'ddl_health_core.dart';
import '../../services/sync_service.dart';

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

    var healthDb = await openDatabase(path, version: 1, onCreate: _createDb);
    healthDbFilePath = path;
    return healthDb;
  }

  void _createDb(Database db, int newVersion) async {
    await db.transaction((txn) async {
      await txn.execute(HealthCoreDdl.ddlSteps);
      await txn.execute(HealthCoreDdl.ddlSleep);
      await txn.execute(HealthCoreDdl.ddlDiet);
      await txn.execute(HealthCoreDdl.ddlExerciseSession);
    });
  }

  ///***********************************************/
  /// 步数相关操作
  ///

  Future<int> insertOrUpdateSteps(DailySteps steps) async {
    Database db = await database;
    int rst = await db.insert(
      HealthCoreDdl.tableNameSteps,
      steps.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 触发异步同步
    SyncService().syncData();

    return rst;
  }

  Future<List<DailySteps>> queryStepsList({
    String? startDate,
    String? endDate,
  }) async {
    Database db = await database;
    var where = [];
    var whereArgs = [];

    if (startDate != null) {
      where.add("date >= ?");
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where.add("date <= ?");
      whereArgs.add(endDate);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameSteps,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => DailySteps.fromMap(maps[i]));
  }

  ///***********************************************/
  /// 睡眠相关操作
  ///

  Future<int> insertSleep(SleepRecord record) async {
    Database db = await database;
    int rst = await db.insert(HealthCoreDdl.tableNameSleep, record.toMap());

    // 触发异步同步
    SyncService().syncData();

    return rst;
  }

  Future<List<SleepRecord>> querySleepList({int limit = 10}) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameSleep,
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => SleepRecord.fromMap(maps[i]));
  }

  ///***********************************************/
  /// 饮食相关操作
  ///

  Future<int> insertDiet(DietLog log) async {
    Database db = await database;
    int rst = await db.insert(HealthCoreDdl.tableNameDiet, log.toMap());

    // 触发异步同步
    SyncService().syncData();

    return rst;
  }

  Future<List<DietLog>> queryDietList({String? date}) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameDiet,
      where: date != null ? 'date = ?' : null,
      whereArgs: date != null ? [date] : null,
      orderBy: 'gmt_create DESC',
    );
    return List.generate(maps.length, (i) => DietLog.fromMap(maps[i]));
  }

  ///***********************************************/
  /// 运动会话相关操作
  ///

  Future<int> insertExerciseSession(ExerciseSession session) async {
    Database db = await database;
    int rst = await db.insert(
      HealthCoreDdl.tableNameExerciseSession,
      session.toMap(),
    );

    // 触发异步同步
    SyncService().syncData();

    return rst;
  }

  Future<List<ExerciseSession>> queryExerciseSessions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      HealthCoreDdl.tableNameExerciseSession,
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) => ExerciseSession.fromMap(maps[i]));
  }
}
