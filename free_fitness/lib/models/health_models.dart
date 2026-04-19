class DailySteps {
  int? id;
  String date; // yyyy-mm-dd
  int steps;
  double calories;
  String gmtCreate;

  DailySteps({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'steps_id': id,
      'date': date,
      'steps': steps,
      'calories': calories,
      'gmt_create': gmtCreate,
    };
  }

  factory DailySteps.fromMap(Map<String, dynamic> map) {
    return DailySteps(
      id: map['steps_id'] ?? map['stepsId'],
      date: map['date'] ?? "",
      steps: map['steps'] ?? 0,
      calories: (map['calories'] ?? 0.0).toDouble(),
      gmtCreate: map['gmt_create'] ?? map['gmtCreate'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepsId': id,
      'date': date,
      'steps': steps,
      'calories': calories,
      'gmtCreate': gmtCreate,
    };
  }
}

class SleepRecord {
  int? id;
  String startTime;
  String endTime;
  double durationHours;
  String note;
  String gmtCreate;

  SleepRecord({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    this.note = '',
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'sleep_id': id,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'note': note,
      'gmt_create': gmtCreate,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['sleep_id'] ?? map['sleepId'],
      startTime: map['start_time'] ?? map['startTime'] ?? "",
      endTime: map['end_time'] ?? map['endTime'] ?? "",
      durationHours: (map['duration_hours'] ?? map['durationHours'] ?? 0.0)
          .toDouble(),
      note: map['note'] ?? '',
      gmtCreate: map['gmt_create'] ?? map['gmtCreate'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleepId': id,
      'startTime': startTime,
      'endTime': endTime,
      'durationHours': durationHours,
      'note': note,
      'gmtCreate': gmtCreate,
    };
  }
}

class DietLog {
  int? id;
  String date;
  String category; // breakfast, lunch, dinner, snack
  String foodName;
  double calories;
  double protein;
  double fat;
  double carbs;
  double water;
  String gmtCreate;

  DietLog({
    this.id,
    required this.date,
    required this.category,
    required this.foodName,
    required this.calories,
    required this.protein,
    this.fat = 0.0,
    this.carbs = 0.0,
    this.water = 0.0,
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'diet_id': id,
      'date': date,
      'category': category,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'water': water,
      'gmt_create': gmtCreate,
    };
  }

  factory DietLog.fromMap(Map<String, dynamic> map) {
    return DietLog(
      id: map['diet_id'] ?? map['dietId'],
      date: map['date'] ?? "",
      category: map['category'] ?? "",
      foodName: map['food_name'] ?? map['foodName'] ?? "",
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      water: (map['water'] ?? 0.0).toDouble(),
      gmtCreate: map['gmt_create'] ?? map['gmtCreate'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietId': id,
      'date': date,
      'category': category,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'water': water,
      'gmtCreate': gmtCreate,
    };
  }
}

class ExerciseSession {
  int? id;
  String startTime;
  String? endTime;
  double distance;
  int steps;
  String? pathPoints;
  double? calories;
  int? durationSeconds;
  String gmtCreate;

  ExerciseSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.distance = 0,
    this.steps = 0,
    this.pathPoints,
    this.calories,
    this.durationSeconds,
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': id,
      'start_time': startTime,
      'end_time': endTime,
      'distance': distance,
      'steps': steps,
      'path_points': pathPoints,
      'calories': calories,
      'duration_seconds': durationSeconds,
      'gmt_create': gmtCreate,
    };
  }

  factory ExerciseSession.fromMap(Map<String, dynamic> map) {
    return ExerciseSession(
      id: map['session_id'] ?? map['sessionId'],
      startTime: map['start_time'] ?? map['startTime'] ?? "",
      endTime: map['end_time'] ?? map['endTime'],
      distance: (map['distance'] ?? 0.0).toDouble(),
      steps: map['steps'] ?? 0,
      pathPoints: map['path_points'] ?? map['pathPoints'],
      calories: (map['calories'] ?? map['calories'] ?? 0.0).toDouble(),
      durationSeconds: map['duration_seconds'] ?? map['durationSeconds'],
      gmtCreate: map['gmt_create'] ?? map['gmtCreate'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': id,
      'startTime': startTime,
      'endTime': endTime,
      'distance': distance,
      'steps': steps,
      'pathPoints': pathPoints,
      'calories': calories,
      'durationSeconds': durationSeconds,
      'gmtCreate': gmtCreate,
    };
  }
}
