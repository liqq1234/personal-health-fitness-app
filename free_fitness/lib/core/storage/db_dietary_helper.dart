import 'dart:async';

import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../constants/constants.dart';
import '../../models/dietary_state.dart';

class DBDietaryHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDietaryHelper _dbHelper = DBDietaryHelper._createInstance();
  factory DBDietaryHelper() => _dbHelper;

  DBDietaryHelper._createInstance();

  // Stubs for compatibility
  Future<void> deleteDB() async {}
  Future<void> closeDB() async {}
  Future<void> exportDatabase() async {}
  void showTableNameList() {}

  // Helper (Pure Cloud API Wrapper)

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

  // AI 饮食解析 (Cloud)
  Future<AiParseResponse?> parseAiText(String text) async {
    try {
      var response = await HttpUtils.post(
        path: "${ApiEndpoints.dietSync}/parse-ai",
        data: text, // Plain text
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return AiParseResponse.fromJson(response['data']);
      }
    } catch (e) {
      print("AI parsing failed: $e");
    }
    return null;
  }

  Future<NutritionAnalysis?> getAnalysis(String date) async {
    try {
      final response = await HttpUtils.get(
        path: "${ApiEndpoints.dietSync}/analysis",
        queryParameters: {'date': date},
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        return NutritionAnalysis.fromJson(response['data']);
      }
    } catch (e) {
      print("Get analysis failed: $e");
    }
    return null;
  }
}
