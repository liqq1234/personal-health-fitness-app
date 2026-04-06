/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class UserDdl {
  // db名称
  static String databaseName = "embedded_user.db";

  // 饮食摄入目标表
  static const tableNameOfIntakeDailyGoal = 'ff_intake_daily_goal';
  // 用户体重趋势表
  static const tableNameWeightTrend = 'ff_weight_trend';
}
