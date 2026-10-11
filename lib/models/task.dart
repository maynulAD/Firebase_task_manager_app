import 'package:cloud_firestore/cloud_firestore.dart';

class TaskItem {
  const TaskItem({
    this.id = '',
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final bool isCompleted;
  final DateTime? createdAt;

  factory TaskItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return TaskItem(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: parseDate(map['dueDate']),
      priority: map['priority'] as String? ?? 'Medium',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: map['createdAt'] == null ? null : parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'isCompleted': isCompleted,
    };
    if (includeCreatedAt && createdAt != null) {
      data['createdAt'] = Timestamp.fromDate(createdAt!);
    }
    return data;
  }

  TaskItem copyWith({bool? isCompleted}) => TaskItem(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate,
    priority: priority,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
  );
}
