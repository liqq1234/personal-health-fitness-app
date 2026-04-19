import '../core/dio_client/cus_http_client.dart';
import '../core/constants/constants.dart';
import '../models/social.dart';

class SocialApiService {
  // apiBaseUrl 是 .../api/v1
  // 后端是 /api/v1/social
  // 由于 HttpUtils 会直接拼接路径且 apiBaseUrl 末尾没有斜杠，
  // 我们必须在 path 前面加上斜杠以确保生成 .../api/v1/social

  static Future<List<int>> getFriends(
    int userId, {
    bool showLoading = true,
  }) async {
    final response = await HttpUtils.get(
      path: '/social/friends/$userId',
      showLoading: showLoading,
    );
    if (response is Map && response.containsKey('data')) {
      return List<int>.from(response['data'] ?? []);
    }
    return List<int>.from(response ?? []);
  }

  static Future<List<int>> getPendingRequests(int userId) async {
    final response = await HttpUtils.get(
      path: '/social/friends/pending/$userId',
      showLoading: false,
    );
    if (response is Map && response.containsKey('data')) {
      return List<int>.from(response['data'] ?? []);
    }
    return List<int>.from(response ?? []);
  }

  static Future<List<int>> getSentRequests(int userId) async {
    final response = await HttpUtils.get(
      path: '/social/friends/sent/$userId',
      showLoading: false,
    );
    if (response is Map && response.containsKey('data')) {
      return List<int>.from(response['data'] ?? []);
    }
    return List<int>.from(response ?? []);
  }

  // 获取单个用户的信息
  static Future<dynamic> getUser(int userId) async {
    final response = await HttpUtils.get(
      path: '/users/$userId',
      showLoading: false,
    );
    if (response is Map && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  static Future<void> requestFriend(int userId, int friendId) async {
    await HttpUtils.post(
      path: '/social/friends/request',
      queryParameters: {'userId': userId, 'friendId': friendId},
    );
  }

  static Future<void> acceptFriend(int userId, int friendId) async {
    await HttpUtils.post(
      path: '/social/friends/accept',
      queryParameters: {'userId': userId, 'friendId': friendId},
    );
  }

  static Future<List<ChatMessage>> getChatHistory(
    int u1,
    int u2, {
    bool showLoading = false,
  }) async {
    final response = await HttpUtils.get(
      path: '/social/chat/history',
      queryParameters: {'u1': u1, 'u2': u2},
      showLoading: showLoading,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    if (data is! List) return [];
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<ChatMessage> sendMessage(ChatMessage message) async {
    final response = await HttpUtils.post(
      path: '/social/chat/send',
      data: message.toJson(),
      showLoading: true,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    return ChatMessage.fromJson(data);
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final response = await HttpUtils.get(
      path: '/users/search',
      queryParameters: {'query': query},
      showLoading: false,
    );

    dynamic data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;

    if (data == null) return [];
    if (data is List) return data;
    return [data];
  }

  static Future<Map<String, dynamic>> getFriendHealthSummary(
    int friendId,
  ) async {
    final response = await HttpUtils.get(
      path: '/social/health-summary/$friendId',
      queryParameters: {'userId': CacheUser.userId},
      showLoading: false,
    );
    if (response is Map && response.containsKey('data')) {
      return Map<String, dynamic>.from(response['data'] ?? {});
    }
    return Map<String, dynamic>.from(response ?? {});
  }

  static Future<SocialMoment> postMoment(SocialMoment moment) async {
    final response = await HttpUtils.post(
      path: '/social/moments',
      data: moment.toJson(),
      showLoading: true,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    return SocialMoment.fromJson(data);
  }

  static Future<List<SocialMoment>> getTimeline(int userId) async {
    final response = await HttpUtils.get(
      path: '/social/moments/timeline/$userId',
      showLoading: false,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    if (data is! List) return [];
    return data.map((e) => SocialMoment.fromJson(e)).toList();
  }

  static Future<void> postComment(SocialComment comment) async {
    await HttpUtils.post(
      path: '/social/moments/comment',
      data: comment.toJson(),
      showLoading: true,
    );
  }

  static Future<List<SocialComment>> getComments(int momentId) async {
    final response = await HttpUtils.get(
      path: '/social/moments/$momentId/comments',
      showLoading: false,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    if (data is! List) return [];
    return data.map((e) => SocialComment.fromJson(e)).toList();
  }

  static Future<void> toggleLike(int userId, int momentId) async {
    await HttpUtils.post(
      path: '/social/moments/like',
      queryParameters: {'userId': userId, 'momentId': momentId},
      showLoading: false,
    );
  }

  static Future<List<int>> getLikeUserIds(int momentId) async {
    final response = await HttpUtils.get(
      path: '/social/moments/$momentId/likes',
      showLoading: false,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    if (data is! List) return [];
    return List<int>.from(data);
  }

  static Future<bool> isLikedByUser(int userId, int momentId) async {
    final response = await HttpUtils.get(
      path: '/social/moments/$momentId/is-liked',
      queryParameters: {'userId': userId},
      showLoading: false,
    );
    final data = (response is Map && response.containsKey('data'))
        ? response['data']
        : response;
    return data == true;
  }
}
