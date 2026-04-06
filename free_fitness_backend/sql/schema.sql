-- =============================================================================
-- Personal Health & Fitness App - Database Schema (MySQL)
-- Last Updated: 2026-04-03
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. User Module
-- ----------------------------

-- 用户基础信息表
DROP TABLE IF EXISTS `ff_user`;
CREATE TABLE `ff_user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT,
  `user_name` varchar(64) NOT NULL,
  `user_code` varchar(64) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `avatar` varchar(512) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `description` text,
  `date_of_birth` varchar(20) DEFAULT NULL,
  `height` double DEFAULT NULL,
  `height_unit` varchar(10) DEFAULT NULL,
  `current_weight` double DEFAULT NULL,
  `target_weight` double DEFAULT NULL,
  `weight_unit` varchar(10) DEFAULT NULL,
  `rda_goal` int DEFAULT NULL,
  `protein_goal` double DEFAULT NULL,
  `fat_goal` double DEFAULT NULL,
  `cho_goal` double DEFAULT NULL,
  `action_rest_time` int DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 体重趋势记录表 (含 AES-256 加密字段)
DROP TABLE IF EXISTS `ff_weight_trend`;
CREATE TABLE `ff_weight_trend` (
  `weight_trend_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `weight` varchar(512) NOT NULL COMMENT 'Encrypted',
  `weight_unit` varchar(10) NOT NULL,
  `height` double NOT NULL,
  `height_unit` varchar(10) NOT NULL,
  `bmi` varchar(512) NOT NULL COMMENT 'Encrypted',
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`weight_trend_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 每日营养摄入目标表
DROP TABLE IF EXISTS `ff_intake_daily_goal`;
CREATE TABLE `ff_intake_daily_goal` (
  `intake_daily_goal_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `day_of_week` varchar(10) NOT NULL COMMENT 'MON/TUE/WED/THU/FRI/SAT/SUN',
  `rda_daily_goal` int NOT NULL,
  `protein_daily_goal` double NOT NULL,
  `fat_daily_goal` double NOT NULL,
  `cho_daily_goal` double NOT NULL,
  PRIMARY KEY (`intake_daily_goal_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------
-- 2. Training Module
-- ----------------------------

-- 基础动作库
DROP TABLE IF EXISTS `ff_exercise`;
CREATE TABLE `ff_exercise` (
  `exercise_id` bigint NOT NULL AUTO_INCREMENT,
  `exercise_code` varchar(64) NOT NULL,
  `exercise_name` varchar(128) NOT NULL,
  `force` varchar(32) DEFAULT NULL,
  `level` varchar(32) DEFAULT NULL,
  `mechanic` varchar(32) DEFAULT NULL,
  `equipment` varchar(64) DEFAULT NULL,
  `counting_mode` varchar(16) NOT NULL,
  `standard_duration` int NOT NULL DEFAULT '1',
  `instructions` text,
  `tts_notes` text,
  `category` varchar(64) NOT NULL,
  `primary_muscles` text,
  `secondary_muscles` text,
  `images` text,
  `is_custom` tinyint DEFAULT '0',
  `contributor` varchar(64) DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`exercise_id`),
  UNIQUE KEY `uk_exercise_code` (`exercise_code`),
  UNIQUE KEY `uk_exercise_name` (`exercise_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 动作组表
DROP TABLE IF EXISTS `ff_group`;
CREATE TABLE `ff_group` (
  `group_id` bigint NOT NULL AUTO_INCREMENT,
  `group_name` varchar(128) NOT NULL,
  `group_category` varchar(64) NOT NULL,
  `group_level` varchar(32) NOT NULL,
  `consumption` int DEFAULT NULL,
  `time_spent` int DEFAULT NULL,
  `description` text,
  `contributor` varchar(64) DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_group_name` (`group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 动作组内的具体动作配置
DROP TABLE IF EXISTS `ff_action`;
CREATE TABLE `ff_action` (
  `action_id` bigint NOT NULL AUTO_INCREMENT,
  `group_id` bigint NOT NULL,
  `exercise_id` bigint NOT NULL,
  `frequency` int DEFAULT NULL,
  `duration` int DEFAULT NULL,
  `equipment_weight` double DEFAULT NULL,
  PRIMARY KEY (`action_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 训练计划表
DROP TABLE IF EXISTS `ff_plan`;
CREATE TABLE `ff_plan` (
  `plan_id` bigint NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(64) NOT NULL,
  `plan_name` varchar(128) NOT NULL,
  `plan_category` varchar(64) NOT NULL,
  `plan_level` varchar(32) NOT NULL,
  `plan_period` int NOT NULL,
  `description` text,
  `contributor` varchar(64) DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`plan_id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`),
  UNIQUE KEY `uk_plan_name` (`plan_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 训练计划与动作组关联表
DROP TABLE IF EXISTS `ff_plan_has_group`;
CREATE TABLE `ff_plan_has_group` (
  `plan_has_group_id` bigint NOT NULL AUTO_INCREMENT,
  `plan_id` bigint NOT NULL,
  `group_id` bigint NOT NULL,
  `day_number` int NOT NULL,
  PRIMARY KEY (`plan_has_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 训练完成日志表
DROP TABLE IF EXISTS `ff_trained_detail_log`;
CREATE TABLE `ff_trained_detail_log` (
  `trained_detail_log_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `trained_date` varchar(12) DEFAULT NULL,
  `plan_name` varchar(128) DEFAULT NULL,
  `plan_category` varchar(64) DEFAULT NULL,
  `plan_level` varchar(32) DEFAULT NULL,
  `day_number` int DEFAULT NULL,
  `group_name` varchar(128) DEFAULT NULL,
  `group_category` varchar(64) DEFAULT NULL,
  `group_level` varchar(32) DEFAULT NULL,
  `consumption` int DEFAULT NULL,
  `trained_start_time` varchar(30) NOT NULL,
  `trained_end_time` varchar(30) NOT NULL,
  `trained_duration` int NOT NULL,
  `totol_paused_time` int NOT NULL,
  `total_rest_time` int NOT NULL,
  PRIMARY KEY (`trained_detail_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 预训练计划排程表
DROP TABLE IF EXISTS `ff_training_schedule`;
CREATE TABLE `ff_training_schedule` (
  `schedule_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `training_type` varchar(20) NOT NULL COMMENT 'PLAN / GROUP / ACTIVITY',
  `training_name` varchar(100) DEFAULT NULL,
  `target_id` bigint DEFAULT NULL,
  `scheduled_date` varchar(12) NOT NULL,
  `start_time` varchar(10) NOT NULL,
  `end_time` varchar(10) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'PENDING',
  `remind_before_minutes` int DEFAULT '15',
  `remind_sent` int DEFAULT '0',
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------
-- 3. Dietary Module
-- ----------------------------

-- 食物库
DROP TABLE IF EXISTS `ff_food`;
CREATE TABLE `ff_food` (
  `food_id` bigint NOT NULL AUTO_INCREMENT,
  `brand` varchar(128) NOT NULL,
  `product` varchar(128) NOT NULL,
  `description` text,
  `photos` text,
  `tags` text,
  `category` varchar(64) DEFAULT NULL,
  `contributor` varchar(64) DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `is_deleted` tinyint DEFAULT '0',
  PRIMARY KEY (`food_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 食物营养素规格表
DROP TABLE IF EXISTS `ff_serving_info`;
CREATE TABLE `ff_serving_info` (
  `serving_info_id` bigint NOT NULL AUTO_INCREMENT,
  `food_id` bigint NOT NULL,
  `serving_size` int NOT NULL,
  `serving_unit` varchar(20) NOT NULL,
  `energy` double NOT NULL,
  `energy_kcal` double DEFAULT NULL,
  `protein` double NOT NULL,
  `total_fat` double NOT NULL,
  `saturated_fat` double DEFAULT NULL,
  `trans_fat` double DEFAULT NULL,
  `polyunsaturated_fat` double DEFAULT NULL,
  `monounsaturated_fat` double DEFAULT NULL,
  `cholesterol` double DEFAULT NULL,
  `total_carbohydrate` double NOT NULL,
  `sugar` double DEFAULT NULL,
  `dietary_fiber` double DEFAULT NULL,
  `sodium` double NOT NULL,
  `potassium` double DEFAULT NULL,
  `contributor` varchar(64) DEFAULT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `update_user` varchar(64) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  `is_deleted` tinyint DEFAULT '0',
  PRIMARY KEY (`serving_info_id`),
  UNIQUE KEY `uk_food_serving` (`food_id`,`serving_size`,`serving_unit`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 每日饮食条目表
DROP TABLE IF EXISTS `ff_daily_food_item`;
CREATE TABLE `ff_daily_food_item` (
  `daily_food_item_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `date` varchar(12) NOT NULL,
  `meal_category` varchar(20) NOT NULL,
  `food_id` bigint NOT NULL,
  `food_intake_size` double NOT NULL,
  `serving_info_id` bigint NOT NULL,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`daily_food_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 餐次照片表
DROP TABLE IF EXISTS `ff_meal_photo`;
CREATE TABLE `ff_meal_photo` (
  `meal_photo_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `date` varchar(12) NOT NULL,
  `meal_category` varchar(20) NOT NULL,
  `photos` text NOT NULL COMMENT 'JSON Array',
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`meal_photo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------
-- 4. Health & Diary & System
-- ----------------------------

-- 运动会话轨迹表
DROP TABLE IF EXISTS `ff_exercise_sessions`;
CREATE TABLE `ff_exercise_sessions` (
  `session_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `start_time` varchar(30) NOT NULL,
  `end_time` varchar(30) DEFAULT NULL,
  `distance` double DEFAULT NULL,
  `steps` int DEFAULT NULL,
  `calories` double DEFAULT NULL,
  `duration_seconds` bigint DEFAULT NULL,
  `path_points` mediumtext COMMENT 'GPS Track JSON',
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 睡眠记录表
DROP TABLE IF EXISTS `ff_sleep_records`;
CREATE TABLE `ff_sleep_records` (
  `sleep_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `start_time` varchar(30) NOT NULL,
  `end_time` varchar(30) NOT NULL,
  `duration_hours` double NOT NULL,
  `note` text,
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`sleep_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 轻量饮食记录简表
DROP TABLE IF EXISTS `ff_diet_logs`;
CREATE TABLE `ff_diet_logs` (
  `diet_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `date` varchar(12) NOT NULL,
  `category` varchar(30) NOT NULL,
  `food_name` varchar(128) NOT NULL,
  `calories` double NOT NULL,
  `protein` double NOT NULL,
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`diet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 每日步数统计表
DROP TABLE IF EXISTS `ff_daily_steps`;
CREATE TABLE `ff_daily_steps` (
  `steps_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `date` varchar(12) NOT NULL,
  `steps` int NOT NULL,
  `calories` double NOT NULL,
  `gmt_create` varchar(30) NOT NULL,
  PRIMARY KEY (`steps_id`),
  UNIQUE KEY `uk_user_date` (`user_id`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 个人日记表
DROP TABLE IF EXISTS `ff_diary`;
CREATE TABLE `ff_diary` (
  `diary_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `date` varchar(12) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` mediumtext NOT NULL COMMENT 'Quill Delta JSON',
  `tags` text,
  `category` varchar(64) DEFAULT NULL,
  `mood` varchar(32) DEFAULT NULL,
  `photos` text,
  `gmt_create` varchar(30) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`diary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户偏好设置表
DROP TABLE IF EXISTS `ff_user_settings`;
CREATE TABLE `ff_user_settings` (
  `setting_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `theme` varchar(32) DEFAULT NULL,
  `language` varchar(16) DEFAULT NULL,
  `gmt_modified` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`setting_id`),
  UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 全量数据备份记录表
DROP TABLE IF EXISTS `ff_backup`;
CREATE TABLE `ff_backup` (
  `backup_id` varchar(36) NOT NULL,
  `user_id` bigint NOT NULL,
  `backup_version` varchar(16) DEFAULT NULL,
  `size_kb` int DEFAULT NULL,
  `data` longtext NOT NULL,
  `saved_at` varchar(30) NOT NULL,
  PRIMARY KEY (`backup_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
