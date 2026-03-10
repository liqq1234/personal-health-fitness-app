class HealthCoreDdl {
  static String databaseName = "embedded_health_core.db";

  static const tableNameSteps = 'ff_daily_steps';
  static const tableNameSleep = 'ff_sleep_records';
  static const tableNameDiet = 'ff_diet_logs';
  static const tableNameExerciseSession = 'ff_exercise_sessions';

  static const String ddlSteps =
      """
    CREATE TABLE $tableNameSteps (
      steps_id    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date        TEXT    NOT NULL UNIQUE,
      steps       INTEGER NOT NULL DEFAULT 0,
      calories    REAL    NOT NULL DEFAULT 0,
      gmt_create  TEXT    NOT NULL
    );
  """;

  static const String ddlSleep =
      """
    CREATE TABLE $tableNameSleep (
      sleep_id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      start_time      TEXT    NOT NULL,
      end_time        TEXT    NOT NULL,
      duration_hours  REAL    NOT NULL,
      note            TEXT,
      gmt_create      TEXT    NOT NULL
    );
  """;

  static const String ddlDiet =
      """
    CREATE TABLE $tableNameDiet (
      diet_id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date        TEXT    NOT NULL,
      category    TEXT    NOT NULL,
      food_name   TEXT    NOT NULL,
      calories    REAL    NOT NULL,
      protein     REAL    NOT NULL,
      gmt_create  TEXT    NOT NULL
    );
  """;

  static const String ddlExerciseSession =
      """
    CREATE TABLE $tableNameExerciseSession (
      session_id  INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      start_time  TEXT    NOT NULL,
      end_time    TEXT,
      distance    REAL    DEFAULT 0,
      steps       INTEGER DEFAULT 0,
      path_points TEXT,
      gmt_create  TEXT    NOT NULL
    );
  """;
}
