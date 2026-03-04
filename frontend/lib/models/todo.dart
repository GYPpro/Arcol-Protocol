class TodoItem {
  final int id;
  final String title;
  final String? description;
  final int priority;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final bool reminderSent;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    required this.completed,
    this.completedAt,
    required this.createdAt,
    required this.reminderSent,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'] ?? 3,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      reminderSent: json['reminder_sent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
    };
  }
}

class TimeSession {
  final int id;
  final String taskName;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final DateTime createdAt;

  TimeSession({
    required this.id,
    required this.taskName,
    this.description,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory TimeSession.fromJson(Map<String, dynamic> json) {
    return TimeSession(
      id: json['id'],
      taskName: json['task_name'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TimeSessionActive {
  final bool isActive;
  final TimeSession? session;

  TimeSessionActive({
    required this.isActive,
    this.session,
  });

  factory TimeSessionActive.fromJson(Map<String, dynamic> json) {
    return TimeSessionActive(
      isActive: json['is_active'] ?? false,
      session: json['session'] != null ? TimeSession.fromJson(json['session']) : null,
    );
  }
}
