import '../core/dio_client/api_endpoints.dart';
import '../core/dio_client/cus_http_client.dart';
import '../models/user_state.dart';

class UserApiService {
  // 单例模式
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

  /// 注册新用户到云端 (Create/Register User on Cloud)
  Future<bool> registerUser(User user) async {
    try {
      // 将 User 对象转换为 Map 发送给后端
      var response = await HttpUtils.post(
        path: ApiEndpoints.userRegister,
        data: user.toJson(),
      );
      // 后端返回 Result<TokenResponse>
      return response != null && response['code'] == 200;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新云端用户信息 (Update user on Cloud)
  Future<bool> updateUser(User user) async {
    try {
      var response = await HttpUtils.put(
        path: "${ApiEndpoints.userUpdate}/${user.userId}",
        data: user.toJson(),
      );
      // 后端返回 Result<User>，data 字段是 User 对象
      return response != null && response['code'] == 200;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取个人资料 (Fetch profile from Cloud)
  Future<User?> getProfile(int userId) async {
    try {
      var response = await HttpUtils.get(
        path: "${ApiEndpoints.userProfile}/$userId",
      );
      if (response != null && response['data'] != null) {
        return User.fromMap(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
