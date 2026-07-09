class TaskModel {
  final String id;
  final String text;
  final String? quad; // q1, q2, q3, q4, or null (inbox)
  final String day; // YYYY-MM-DD
  final int carried;
  final String? description;

  const TaskModel({
    required this.id,
    required this.text,
    this.quad,
    required this.day,
    this.carried = 0,
    this.description,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      quad: map['quad'] as String?,
      day: map['day'] as String? ?? '',
      carried: (map['carried'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'quad': quad,
        'day': day,
        'carried': carried,
        'description': description,
      };

  TaskModel copyWith({
    String? id,
    String? text,
    String? quad,
    String? day,
    int? carried,
    String? description,
  }) =>
      TaskModel(
        id: id ?? this.id,
        text: text ?? this.text,
        quad: quad ?? this.quad,
        day: day ?? this.day,
        carried: carried ?? this.carried,
        description: description ?? this.description,
      );
}

class DoneItem {
  final String id;
  final String text;
  final String? quad;
  final String date;
  final String completedAt;
  final String? description;

  const DoneItem({
    required this.id,
    required this.text,
    this.quad,
    required this.date,
    required this.completedAt,
    this.description,
  });

  factory DoneItem.fromMap(Map<String, dynamic> map) {
    return DoneItem(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      quad: map['quad'] as String?,
      date: map['date'] as String? ?? '',
      completedAt: map['completedAt'] as String? ?? '',
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'quad': quad,
        'date': date,
        'completedAt': completedAt,
        'description': description,
      };
}

class DayData {
  final List<TaskModel> tasks;
  final List<DoneItem> done;
  final List<TaskModel> backlog;
  final String? lastReviewDate;
  final String? lastRolloverDate;

  const DayData({
    this.tasks = const [],
    this.done = const [],
    this.backlog = const [],
    this.lastReviewDate,
    this.lastRolloverDate,
  });

  factory DayData.empty() => const DayData();

  factory DayData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DayData.empty();
    return DayData(
      tasks: ((map['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .map(TaskModel.fromMap)
          .toList(),
      done: ((map['done'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .map(DoneItem.fromMap)
          .toList(),
      backlog: ((map['backlog'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .map(TaskModel.fromMap)
          .toList(),
      lastReviewDate: map['lastReviewDate'] as String?,
      lastRolloverDate: map['lastRolloverDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'done': done.map((d) => d.toMap()).toList(),
        'backlog': backlog.map((t) => t.toMap()).toList(),
        if (lastReviewDate != null) 'lastReviewDate': lastReviewDate,
        if (lastRolloverDate != null) 'lastRolloverDate': lastRolloverDate,
      };

  DayData copyWith({
    List<TaskModel>? tasks,
    List<DoneItem>? done,
    List<TaskModel>? backlog,
    String? lastReviewDate,
    String? lastRolloverDate,
  }) =>
      DayData(
        tasks: tasks ?? this.tasks,
        done: done ?? this.done,
        backlog: backlog ?? this.backlog,
        lastReviewDate: lastReviewDate ?? this.lastReviewDate,
        lastRolloverDate: lastRolloverDate ?? this.lastRolloverDate,
      );
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin' or 'user'

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'user',
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
}
