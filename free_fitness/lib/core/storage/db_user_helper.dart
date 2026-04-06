// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/user_state.dart';

import 'ddl_user.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';

class DBUserHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBUserHelper _dbHelper = DBUserHelper._createInstance();
  // 构造函数，返回单例
  factory DBUserHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var userDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBUserHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取存储数据库的目录路径
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path, UserDdl.databaseName);

    print("初始化 User sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var userDb = await openDatabase(path, version: 1, onCreate: _createDb);
    userDbFilePath = path;
    return userDb;
  }

  // 创建训练数据库相关表 (Decommissioned profile tables)
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb (Profile tables moved to cloud)……");
    // No local tables for user profile anymore
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("User db.isOpen ${db.isOpen}");
    await db.close();
    print("User db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite User db文件，db文件地址：$userDbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(userDbFilePath);

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

    print("User DB中拥有的表名:------------");
    print(tableNames);
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

      // print('表 $tableName 已成功导出到：$tempFilePath');
    }
  }

  ///
  ///  Helper 的相关方法 (Cloud Only for User)
  ///

  // 查询用户 (Only from Cloud)
  Future<User?> queryUser({int? userId}) async {
    if (userId == null) return null;
    try {
      var response = await HttpUtils.get(
        path: "/users/$userId",
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
          path: "${ApiEndpoints.intakeGoals}/${goals[0].userId}",
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
        path: "/users/$userId",
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
        path: "${ApiEndpoints.intakeGoals}/$userId",
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
          path: "${ApiEndpoints.intakeGoals}/${goals[0].userId}",
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
          path: ApiEndpoints.weightTrends,
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
          path: "${ApiEndpoints.weightTrends}/${item.weightTrendId}",
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
        path: "${ApiEndpoints.weightTrends}/$userId",
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
