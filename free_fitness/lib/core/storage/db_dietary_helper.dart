// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dietary_state.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';
import 'ddl_dietary.dart';

class DBDietaryHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDietaryHelper _dbHelper = DBDietaryHelper._createInstance();
  // 构造函数，返回单例
  factory DBDietaryHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dietaryDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDietaryHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取存储数据库的目录路径
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path, DietaryDdl.databaseName);

    print("初始化 DIETARY sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var dietaryDb = await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );

    dietaryDbFilePath = path;
    return dietaryDb;
  }

  // 创建训练数据库相关表 (Decommissioned)
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb (Dietary moved to cloud)……");
  }

  // 数据库升级 (Decommissioned)
  void _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print("数据库升级 _upgradeDb (Dietary moved to cloud)……");
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("Dietary db.isOpen ${db.isOpen}");
    await db.close();
    print("Dietary db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite Dietary db文件，db文件地址：$dietaryDbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dietaryDbFilePath);

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

    print("DietaryDB中拥有的表名:------------");
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
    }
  }

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// food and serving_info 的相关操作
  ///

  // 修改单条基础 food (Only to Cloud)
  Future<int> updateFood(Food food) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.dietSync}/foods/${food.foodId}",
        data: food.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update food failed: $e");
      return 0;
    }
  }

  ///
  // 插入单条食物(返回食物编号和营养素编号列表，0和空可能就没插入成功)
  // 如果食物为空，servinginfo不为空，说明是给以存在的食物添加单份营养素
  // 如果食物不为空，servinginfo为空，说明是单独新增食物（正常业务应该不会，新增食物一定会带一份营养素）
  // 如果食物不为空，servinginfo不为空，说明是正常的新增食物带一份营养素(支持1个食物带多份营养素信息)
  // 如果都为空，则报错

  // 插入食物带上营养素列表 (Cloud First)
  Future<Map<String, Object>> insertFoodWithServingInfoList({
    Food? food,
    List<ServingInfo>? servingInfoList,
  }) async {
    try {
      var response = await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/foods/with-servings",
        data: {
          "food": food?.toJson(),
          "servings": servingInfoList?.map((e) => e.toJson()).toList(),
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return {
          "foodId": response['data']['foodId'] ?? 0,
          "servingIds": response['data']['servingIds'] ?? [],
        };
      }
    } catch (e) {
      print("Sync food with servings failed: $e");
    }
    return {"foodId": 0, "servingIds": []};
  }

  // 批量插入 food (Safe to ignore for now or map to cloud)
  Future<List<Object?>> insertFoodList(List<Food> foods) async {
    for (var food in foods) {
      await updateFood(food); // Bulk save logic
    }
    return [];
  }

  Future<void> updateFoodWithServingInfo(
    Food food,
    ServingInfo servingInfo,
  ) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.dietSync}/foods/with-servings/${food.foodId}",
        data: {"food": food.toJson(), "serving": servingInfo.toJson()},
        showLoading: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateSingleServingInfo(ServingInfo servingInfo) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.dietSync}/servings/${servingInfo.servingInfoId}",
        data: servingInfo.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update serving failed: $e");
      return 0;
    }
  }

  // 删除单条数据 (Cloud)
  Future<dynamic> deleteFoodWithServingInfo(int foodId) async {
    try {
      return await HttpUtils.delete(
        path: "${ApiEndpoints.dietSync}/foods/$foodId",
        showLoading: false,
      );
    } catch (e) {
      throw Exception("删除食物及其所有单份营养素出错: $e");
    }
  }

  // 数据库备份全量导入时每个文件夹单独导出，需要用到 (Cloud)
  Future<List<Object?>> insertServingInfoList(List<ServingInfo> siList) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/servings/batch",
        data: siList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync servings failed: $e");
      return [];
    }
  }

  // 删除营养素数据列表 (Cloud)
  Future<List<Object?>> deleteServingInfoList(List<int> ids) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/servings/batch-delete",
        data: ids,
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch delete servings failed: $e");
      return [];
    }
  }

  // 关键字查询食物及其不同单份食物营养素
  Future<CusDataResult> searchFoodWithServingInfoWithPagination(
    String keyword,
    int page,
    int pageSize, {
    // 2023-12-31 指定创建日期升序或者降序排序
    String? dateSort = "desc",
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/foods/search",
        queryParameters: {
          "keyword": keyword,
          "page": page,
          "pageSize": pageSize,
          "dateSort": dateSort,
        },
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var resultData = response['data'];
        List<dynamic> list = resultData['list'] ?? [];
        int total = resultData['total'] ?? 0;
        return CusDataResult(
          data: list
              .map(
                (e) => FoodAndServingInfo(
                  food: Food.fromMap(e['food']),
                  servingInfoList: (e['servings'] as List)
                      .map((s) => ServingInfo.fromMap(s))
                      .toList(),
                ),
              )
              .toList(),
          total: total,
        );
      }
    } catch (e) {
      print("Search food failed: $e");
    }
    return CusDataResult(data: [], total: 0);
  }

  // 查询指定食物的单份营养素信息
  Future<FoodAndServingInfo?> searchFoodWithServingInfoByFoodId(
    int foodId, {
    // 2023-12-14 默认查询的都是排除了逻辑删除后的数据，只有涉及到饮食摄入条目的才查询所有
    bool onlyNotDeleted = true,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/foods/$foodId",
        queryParameters: {"onlyNotDeleted": onlyNotDeleted},
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        var data = response['data'];
        return FoodAndServingInfo(
          food: Food.fromMap(data['food']),
          servingInfoList: (data['servings'] as List)
              .map((e) => ServingInfo.fromMap(e))
              .toList(),
        );
      }
    } catch (e) {
      print("Get food by id failed: $e");
    }
    return null;
  }

  ///***********************************************/
  /// daily_food_item 的相关操作
  ///

  // 批量插入饮食日记条目
  Future<List<Object?>> insertDailyFoodItemList(
    List<DailyFoodItem> dfiList,
  ) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/logs/batch",
        data: dfiList.map((e) => e.toJson()).toList(),
        showLoading: false,
      );
      return [];
    } catch (e) {
      print("Batch sync daily food items failed: $e");
      return [];
    }
  }

  // 修改单条 daily_food_item
  Future<int> updateDailyFoodItem(DailyFoodItem dailyFoodItem) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.dietSync}/logs/${dailyFoodItem.dailyFoodItemId}",
        data: dailyFoodItem.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update daily food item failed: $e");
      return 0;
    }
  }

  // 删除单条 daily_food_item
  Future<int> deleteDailyFoodItem(int dailyFoodItemId) async {
    try {
      await HttpUtils.delete(
        path: "${ApiEndpoints.dietSync}/logs/$dailyFoodItemId",
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Delete daily food item failed: $e");
      return 0;
    }
  }

  // 条件查询日记条目，可以带food和serving info 详情
  // 返回值动态类型，有查详情则是 List<DailyFoodItemWithFoodServing>，
  // 不查详情则是 List<DailyFoodItem>
  // 条件查询日记条目，可以带food和serving info 详情 (Cloud)
  Future<List<dynamic>> queryDailyFoodItemListWithDetail({
    int? userId,
    int? dailyFoodItemId,
    String? startDate,
    String? endDate,
    String? mealCategory,
    bool withDetail = false,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/logs/detail",
        queryParameters: {
          "userId": userId ?? CacheUser.userId,
          if (dailyFoodItemId != null) "dailyFoodItemId": dailyFoodItemId,
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
          if (mealCategory != null) "mealCategory": mealCategory,
          "withDetail": withDetail,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        if (withDetail) {
          return list
              .map(
                (e) => DailyFoodItemWithFoodServing(
                  dailyFoodItem: DailyFoodItem.fromMap(e['dailyFoodItem']),
                  food: Food.fromMap(e['food']),
                  servingInfo: ServingInfo.fromMap(e['serving']),
                ),
              )
              .toList();
        } else {
          return list.map((e) => DailyFoodItem.fromMap(e)).toList();
        }
      }
    } catch (e) {
      print("Query daily food detail failed: $e");
    }
    return [];
  }

  ///***********************************************/
  /// meal_photo 的相关操作
  ///
  // 插入单条餐次照片 (Cloud)
  Future<int> insertMealPhoto(MealPhoto mp) async {
    try {
      await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/photos",
        data: mp.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Sync meal photo failed: $e");
      return 0;
    }
  }

  Future<List<Object?>> insertMealPhotoList(List<MealPhoto> mpList) async {
    for (var mp in mpList) {
      await insertMealPhoto(mp);
    }
    return [];
  }

  // 修改单条餐次照片
  Future<int> updateMealPhoto(MealPhoto mp) async {
    try {
      await HttpUtils.put(
        path: "${ApiEndpoints.dietSync}/photos/${mp.mealPhotoId}",
        data: mp.toJson(),
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Update meal photo failed: $e");
      return 0;
    }
  }

  // 删除单条餐次照片
  Future<int> deleteMealPhotoById(int mealPhotoId) async {
    try {
      await HttpUtils.delete(
        path: "${ApiEndpoints.dietSync}/photos/$mealPhotoId",
        showLoading: false,
      );
      return 1;
    } catch (e) {
      print("Delete meal photo failed: $e");
      return 0;
    }
  }

  // 查询餐次照片
  // 常用的就是指定日期(只有一天起止一样)和指定餐次(也只能查属于自己的照片)
  // 查询餐次照片 (Cloud)
  Future<List<MealPhoto>> queryMealPhotoList(
    int userId, {
    String? startDate,
    String? endDate,
    String? mealCategory,
    // 默认查所有，相册模块时可能一次性查询10条，上滑加载更多
    int? page,
    int? pageSize,
    // 还可以指定日期排序
    String? dateSort,
  }) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/photos",
        queryParameters: {
          "userId": userId,
          if (startDate != null) "startDate": startDate,
          if (endDate != null) "endDate": endDate,
          if (mealCategory != null) "mealCategory": mealCategory,
          if (page != null) "page": page,
          if (pageSize != null) "pageSize": pageSize,
          "dateSort": dateSort,
        },
        showLoading: false,
      );
      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        List<dynamic> list = response['data'];
        return list.map((e) => MealPhoto.fromMap(e)).toList();
      }
    } catch (e) {
      print("Query meal photo failed: $e");
    }
    return [];
  }
}
