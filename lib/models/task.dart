import 'category.dart';

enum TaskPriority {
  rendah('Rendah'),
  sedang('Sedang'),
  tinggi('Tinggi');

  const TaskPriority(this.label);
  final String label;
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.note = '',
    this.priority = TaskPriority.sedang,
    this.categoryId = defaultCategoryId,
    this.isDone = false,
    this.alarmEnabled = true,
    this.reminderOffsetsMinutes = const [30, 0],
  });

  final String id;
  final String title;
  final String note;
  final DateTime dueDate;
  final TaskPriority priority;
  final String categoryId;
  final bool isDone;

  /// Apakah alarm pengingat deadline aktif untuk tugas ini.
  final bool alarmEnabled;

  /// Daftar menit-sebelum-deadline untuk tiap alarm (0 = tepat saat
  /// deadline). Bisa berisi lebih dari satu nilai, jadi alarm boleh
  /// berbunyi beberapa kali untuk satu tugas, misalnya [1440, 60, 30, 0].
  final List<int> reminderOffsetsMinutes;

  Task copyWith({
    String? title,
    String? note,
    DateTime? dueDate,
    TaskPriority? priority,
    String? categoryId,
    bool? isDone,
    bool? alarmEnabled,
    List<int>? reminderOffsetsMinutes,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      isDone: isDone ?? this.isDone,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      reminderOffsetsMinutes:
          reminderOffsetsMinutes ?? this.reminderOffsetsMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.name,
        'category': categoryId,
        'isDone': isDone,
        'alarm': alarmEnabled,
        'reminders': reminderOffsetsMinutes,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      note: (json['note'] as String?) ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: TaskPriority.values.byName(json['priority'] as String),
      categoryId: (json['category'] as String?) ?? defaultCategoryId,
      isDone: (json['isDone'] as bool?) ?? false,
      alarmEnabled: (json['alarm'] as bool?) ?? true,
      reminderOffsetsMinutes: (json['reminders'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [30, 0],
    );
  }
}
