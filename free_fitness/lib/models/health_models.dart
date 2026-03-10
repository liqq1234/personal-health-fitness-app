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
      id: map['steps_id'],
      date: map['date'],
      steps: map['steps'],
      calories: map['calories'],
      gmtCreate: map['gmt_create'],
    );
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
      id: map['sleep_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      durationHours: map['duration_hours'],
      note: map['note'] ?? '',
      gmtCreate: map['gmt_create'],
    );
  }
}

class DietLog {
  int? id;
  String date;
  String category; // breakfast, lunch, dinner, snack
  String foodName;
  double calories;
  double protein;
  String gmtCreate;

  DietLog({
    this.id,
    required this.date,
    required this.category,
    required this.foodName,
    required this.calories,
    required this.protein,
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
      'gmt_create': gmtCreate,
    };
  }

  factory DietLog.fromMap(Map<String, dynamic> map) {
    return DietLog(
      id: map['diet_id'],
      date: map['date'],
      category: map['category'],
      foodName: map['food_name'],
      calories: map['calories'],
      protein: map['protein'],
      gmtCreate: map['gmt_create'],
    );
  }
}

class ExerciseSession {
  int? id;
  String startTime;
  String? endTime;
  double distance;
  int steps;
  String? pathPoints;
  String gmtCreate;

  ExerciseSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.distance = 0,
    this.steps = 0,
    this.pathPoints,
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
      'gmt_create': gmtCreate,
    };
  }

  factory ExerciseSession.fromMap(Map<String, dynamic> map) {
    return ExerciseSession(
      id: map['session_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      distance: map['distance'],
      steps: map['steps'],
      pathPoints: map['path_points'],
      gmtCreate: map['gmt_create'],
    );
  }
}
