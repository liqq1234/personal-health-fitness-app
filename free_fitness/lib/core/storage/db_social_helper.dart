import '../dio_client/cus_http_client.dart';
import '../dio_client/api_endpoints.dart';
import '../../models/social.dart';

class DBSocialHelper {
  // --- Friendship ---
  static Future<void> requestFriend(int userId, int friendId) async {
    await HttpUtils.post(
      path: "${ApiEndpoints.socialSync}/friends/request",
      queryParameters: {'userId': userId, 'friendId': friendId},
      showLoading: false,
    );
  }

  static Future<void> acceptFriend(int userId, int friendId) async {
    await HttpUtils.post(
      path: "${ApiEndpoints.socialSync}/friends/accept",
      queryParameters: {'userId': userId, 'friendId': friendId},
      showLoading: false,
    );
  }

  static Future<List<int>> getFriends(int userId) async {
    final response = await HttpUtils.get(
      path: "${ApiEndpoints.socialSync}/friends/$userId",
      showLoading: false,
    );
    if (response != null && response['data'] != null) {
      return List<int>.from(response['data']);
    }
    return [];
  }

  // --- Moments ---
  static Future<SocialMoment> postMoment(SocialMoment moment) async {
    final response = await HttpUtils.post(
      path: "${ApiEndpoints.socialSync}/moments",
      data: moment.toJson(),
      showLoading: false,
    );
    return SocialMoment.fromJson(response['data']);
  }

  static Future<List<SocialMoment>> getTimeline(int userId) async {
    final response = await HttpUtils.get(
      path: "${ApiEndpoints.socialSync}/moments/timeline/$userId",
      showLoading: false,
    );
    if (response != null && response['data'] != null) {
      return (response['data'] as List)
          .map((i) => SocialMoment.fromJson(i))
          .toList();
    }
    return [];
  }

  // --- Chat ---
  static Future<ChatMessage> sendMessage(ChatMessage message) async {
    final response = await HttpUtils.post(
      path: "${ApiEndpoints.socialSync}/chat/send",
      data: message.toJson(),
      showLoading: false,
    );
    return ChatMessage.fromJson(response['data']);
  }

  static Future<List<ChatMessage>> getChatHistory(int u1, int u2) async {
    final response = await HttpUtils.get(
      path: "${ApiEndpoints.socialSync}/chat/history",
      queryParameters: {'u1': u1, 'u2': u2},
      showLoading: false,
    );
    if (response != null && response['data'] != null) {
      return (response['data'] as List)
          .map((i) => ChatMessage.fromJson(i))
          .toList();
    }
    return [];
  }
}
