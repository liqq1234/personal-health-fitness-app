import 'package:dio/dio.dart';

import 'cus_http_request.dart';

// 来源：https://www.cnblogs.com/luoshang/p/16987781.html

/// 调用底层的request，重新提供get，post等方便方法

class HttpUtils {
  static HttpRequest httpRequest = HttpRequest();

  /// get
  static Future get({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic headers,
    CusRespType? responseType,
    String? contentType,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.get,
      queryParameters: queryParameters,
      responseType: responseType,
      contentType: contentType,
      headers: headers,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }

  /// post
  static Future post({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters, // 2024-04-18 新增支持参数在url
    dynamic headers,
    CusRespType? responseType,
    String? contentType,
    CancelToken? cancelToken,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.post,
      data: data,
      queryParameters: queryParameters,
      responseType: responseType,
      contentType: contentType,
      headers: headers,
      cancelToken: cancelToken,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }

  /// put
  static Future put({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters, // 2024-04-18 新增支持参数在url
    dynamic headers,
    CusRespType? responseType,
    String? contentType,
    CancelToken? cancelToken,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.put,
      data: data,
      queryParameters: queryParameters,
      responseType: responseType,
      contentType: contentType,
      headers: headers,
      cancelToken: cancelToken,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }

  /// delete
  static Future delete({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic headers,
    CusRespType? responseType,
    String? contentType,
    CancelToken? cancelToken,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.delete,
      queryParameters: queryParameters,
      data: data,
      responseType: responseType,
      contentType: contentType,
      headers: headers,
      cancelToken: cancelToken,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }
}
