// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import '../constants/constants.dart';

class RequestInterceptor extends Interceptor {
  const RequestInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('【onRequest】进入了dio的请求拦截器');
    // 2026-04-17 注入 X-User-Id 请求头，用于后端区分多用户（无需密钥模式）
    // 使用 CacheUser.userId 获取缓存的用户编号，如果没有则默认传 1
    int userId = CacheUser.userId;
    options.headers['X-User-Id'] = userId.toString();

    // 2026-04-17 根据用户要求，彻底移除本地后端的 Authorization Token 注入逻辑，应用本地化运行。
    // 注意：AI 等外部接口仍需保留 Authorization 头，所以这里只针对 apiBaseUrl 路径进行操作。
    if (options.path.startsWith(apiBaseUrl)) {
      options.headers.remove('Authorization');
    }
    return handler.next(options);
  }
}
