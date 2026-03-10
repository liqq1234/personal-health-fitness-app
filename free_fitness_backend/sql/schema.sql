-- =====================================================
-- Free Fitness Backend - MySQL Schema
-- 与前端 ddl_*.dart 完全对齐
-- =====================================================

CREATE DATABASE IF NOT EXISTS free_fitness DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE free_fitness;

-- =====================================================
-- 用户模块（对应 ddl_user.dart）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_user (
    user_id          BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_name        VARCHAR(64)  NOT NULL,
    user_code        VARCHAR(64),
    gender           VARCHAR(10),
    avatar           VARCHAR(512),           -- 头像文件 URL
    password         VARCHAR(255),           -- BCrypt 哈希
    description      TEXT,
    date_of_birth    VARCHAR(20),
    height           DOUBLE,
    height_unit      VARCHAR(10),
    current_weight   DOUBLE,
    target_weight    DOUBLE,
    weight_unit      VARCHAR(10),
    rda_goal         INT,
    protein_goal     DOUBLE,
    fat_goal         DOUBLE,
    cho_goal         DOUBLE,
    action_rest_time INT,
    gmt_create       VARCHAR(30),
    gmt_modified     VARCHAR(30),
    UNIQUE KEY uk_user_name_code (user_name, user_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_weight_trend (
    weight_trend_id  BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id          BIGINT       NOT NULL,
    weight           VARCHAR(512) NOT NULL,  -- AES-256 加密存储
    weight_unit      VARCHAR(10)  NOT NULL,
    height           DOUBLE       NOT NULL,
    height_unit      VARCHAR(10)  NOT NULL,
    bmi              VARCHAR(512) NOT NULL,  -- AES-256 加密存储
    gmt_create       VARCHAR(30)  NOT NULL,
    KEY idx_wt_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_intake_daily_goal (
    intake_daily_goal_id BIGINT  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id              BIGINT  NOT NULL,
    day_of_week          VARCHAR(10) NOT NULL,   -- MON/TUE/WED/THU/FRI/SAT/SUN
    rda_daily_goal       INT     NOT NULL,
    protein_daily_goal   DOUBLE  NOT NULL,
    fat_daily_goal       DOUBLE  NOT NULL,
    cho_daily_goal       DOUBLE  NOT NULL,
    KEY idx_idg_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 健康仪表板模块（对应 ddl_health_core.dart）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_daily_steps (
    steps_id    BIGINT  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT  NOT NULL,
    `date`       VARCHAR(12) NOT NULL,
    steps       INT     NOT NULL DEFAULT 0,
    calories    DOUBLE  NOT NULL DEFAULT 0,
    gmt_create  VARCHAR(30) NOT NULL,
    UNIQUE KEY uk_steps_user_date (user_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_sleep_records (
    sleep_id        BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    start_time      VARCHAR(30) NOT NULL,
    end_time        VARCHAR(30) NOT NULL,
    duration_hours  DOUBLE      NOT NULL,
    note            TEXT,
    gmt_create      VARCHAR(30) NOT NULL,
    KEY idx_sleep_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_diet_logs (
    diet_id    BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT      NOT NULL,
    `date`      VARCHAR(12) NOT NULL,
    category   VARCHAR(30) NOT NULL,
    food_name  VARCHAR(128) NOT NULL,
    calories   DOUBLE      NOT NULL,
    protein    DOUBLE      NOT NULL,
    gmt_create VARCHAR(30) NOT NULL,
    KEY idx_dl_user_date (user_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_exercise_sessions (
    session_id   BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    start_time   VARCHAR(30) NOT NULL,
    end_time     VARCHAR(30),
    distance     DOUBLE DEFAULT 0,
    steps        INT    DEFAULT 0,
    path_points  MEDIUMTEXT,               -- JSON 数组，存 GPS 轨迹点
    gmt_create   VARCHAR(30) NOT NULL,
    KEY idx_es_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 训练模块（对应 ddl_training.dart）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_exercise (
    exercise_id       BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    exercise_code     VARCHAR(64)  NOT NULL UNIQUE,
    exercise_name     VARCHAR(128) NOT NULL UNIQUE,
    `force`           VARCHAR(32),
    `level`           VARCHAR(32),
    mechanic          VARCHAR(32),
    equipment         VARCHAR(64),
    counting_mode     VARCHAR(16)  NOT NULL,
    standard_duration INT          NOT NULL DEFAULT 1,
    instructions      TEXT,
    tts_notes         TEXT,
    category          VARCHAR(64)  NOT NULL,
    primary_muscles   TEXT,
    secondary_muscles TEXT,
    images            TEXT,
    is_custom         TINYINT DEFAULT 0,
    contributor       VARCHAR(64),
    gmt_create        VARCHAR(30),
    gmt_modified      VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_action (
    action_id        BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    group_id         BIGINT NOT NULL,
    exercise_id      BIGINT NOT NULL,
    frequency        INT,
    duration         INT,
    equipment_weight DOUBLE,
    KEY idx_action_group (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_group (
    group_id       BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    group_name     VARCHAR(128) NOT NULL UNIQUE,
    group_category VARCHAR(64)  NOT NULL,
    `group_level`    VARCHAR(32)  NOT NULL,
    consumption    INT,
    time_spent     INT,
    description    TEXT,
    contributor    VARCHAR(64),
    gmt_create     VARCHAR(30),
    gmt_modified   VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_plan (
    plan_id       BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    plan_code     VARCHAR(64)  NOT NULL UNIQUE,
    plan_name     VARCHAR(128) NOT NULL UNIQUE,
    plan_category VARCHAR(64)  NOT NULL,
    `plan_level`    VARCHAR(32)  NOT NULL,
    plan_period   INT          NOT NULL,
    description   TEXT,
    contributor   VARCHAR(64),
    gmt_create    VARCHAR(30),
    gmt_modified  VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_plan_has_group (
    plan_has_group_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    plan_id           BIGINT NOT NULL,
    group_id          BIGINT NOT NULL,
    day_number        INT    NOT NULL,
    KEY idx_phg_plan (plan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_trained_detail_log (
    trained_detail_log_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id               BIGINT NOT NULL,
    trained_date          VARCHAR(12),
    plan_name             VARCHAR(128),
    plan_category         VARCHAR(64),
    plan_level            VARCHAR(32),
    day_number            INT,
    group_name            VARCHAR(128),
    group_category        VARCHAR(64),
    group_level           VARCHAR(32),
    consumption           INT,
    trained_start_time    VARCHAR(30) NOT NULL,
    trained_end_time      VARCHAR(30) NOT NULL,
    trained_duration      INT         NOT NULL,
    totol_paused_time     INT         NOT NULL,
    total_rest_time       INT         NOT NULL,
    KEY idx_tdl_user_date (user_id, trained_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 饮食模块（对应 ddl_dietary.dart）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_food (
    food_id     BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    brand       VARCHAR(128) NOT NULL,
    product     VARCHAR(128) NOT NULL,
    description TEXT,
    photos      TEXT,
    tags        TEXT,
    category    VARCHAR(64),
    contributor VARCHAR(64),
    gmt_create  VARCHAR(30),
    is_deleted  TINYINT DEFAULT 0,
    UNIQUE KEY uk_food_brand_product (brand, product)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_serving_info (
    serving_info_id       BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    food_id               BIGINT NOT NULL,
    serving_size          INT    NOT NULL,
    serving_unit          VARCHAR(20) NOT NULL,
    energy                DOUBLE NOT NULL,
    energy_kcal           DOUBLE,
    protein               DOUBLE NOT NULL,
    total_fat             DOUBLE NOT NULL,
    saturated_fat         DOUBLE,
    trans_fat             DOUBLE,
    polyunsaturated_fat   DOUBLE,
    monounsaturated_fat   DOUBLE,
    cholesterol           DOUBLE,
    total_carbohydrate    DOUBLE NOT NULL,
    sugar                 DOUBLE,
    dietary_fiber         DOUBLE,
    sodium                DOUBLE NOT NULL,
    potassium             DOUBLE,
    contributor           VARCHAR(64),
    gmt_create            VARCHAR(30),
    update_user           VARCHAR(64),
    gmt_modified          VARCHAR(30),
    is_deleted            TINYINT DEFAULT 0,
    UNIQUE KEY uk_si_food_size_unit (food_id, serving_size, serving_unit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_daily_food_item (
    daily_food_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id            BIGINT NOT NULL,
    `date`               VARCHAR(12) NOT NULL,
    meal_category      VARCHAR(20) NOT NULL,
    food_id            BIGINT NOT NULL,
    food_intake_size   DOUBLE NOT NULL,
    serving_info_id    BIGINT NOT NULL,
    gmt_create         VARCHAR(30),
    gmt_modified       VARCHAR(30),
    KEY idx_dfi_user_date (user_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_meal_photo (
    meal_photo_id  BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    `date`           VARCHAR(12) NOT NULL,
    meal_category  VARCHAR(20) NOT NULL,
    photos         TEXT        NOT NULL,
    gmt_create     VARCHAR(30) NOT NULL,
    KEY idx_mp_user_date (user_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 日记模块（对应 ddl_diary.dart）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_diary (
    diary_id     BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    `date`         VARCHAR(12) NOT NULL,
    title        VARCHAR(255) NOT NULL,
    content      MEDIUMTEXT   NOT NULL,   -- Quill Delta JSON
    tags         TEXT,
    category     VARCHAR(64),
    mood         VARCHAR(32),
    photos       TEXT,
    gmt_create   VARCHAR(30),
    gmt_modified VARCHAR(30),
    KEY idx_diary_user_date (user_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- 系统模块（备份 & 设置）
-- =====================================================

CREATE TABLE IF NOT EXISTS ff_backup (
    backup_id      VARCHAR(36) NOT NULL PRIMARY KEY,   -- UUID
    user_id        BIGINT      NOT NULL,
    backup_version VARCHAR(16),
    size_kb        INT,
    data           LONGTEXT    NOT NULL,               -- 全量 JSON 快照
    saved_at       VARCHAR(30) NOT NULL,
    KEY idx_backup_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ff_user_settings (
    setting_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT NOT NULL UNIQUE,
    theme      VARCHAR(20) DEFAULT 'system',
    language   VARCHAR(10) DEFAULT 'zh',
    gmt_modified VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
