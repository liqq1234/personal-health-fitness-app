import '../constants/constants.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Auth 模块
  static const String userLogin = "$apiBaseUrl/auth/login";
  static const String userRegister = "$apiBaseUrl/auth/register";

  // User 模块
  static const String userUpdate = "$apiBaseUrl/users"; // 后面需要接 /{userId}
  static const String userProfile = "$apiBaseUrl/users"; // 应该后面接 /{userId}

  // Personal Data (Intake Goals, Weight Trends)
  static const String intakeGoals =
      "$apiBaseUrl/users"; // 后面接 /{userId}/intake-goals
  static const String weightTrends =
      "$apiBaseUrl/users"; // 后面接 /{userId}/weight-trends

  // Record 模块
  static const String trainingSync = "$apiBaseUrl/training";
  static const String dietSync = "$apiBaseUrl/dietary";
  static const String healthSync = "$apiBaseUrl/health";
  static const String diarySync = "$apiBaseUrl/diary/entries";
}
