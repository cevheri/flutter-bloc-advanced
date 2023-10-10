import 'user.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isDone;
  final User assignee;

  Task(
    this.date,
    this.isDone,
    this.assignee, {
    required this.id,
    required this.title,
    required this.description,
  });

  factory Task.copy(Task task) => Task(
        task.date,
        task.isDone,
        task.assignee,
        id: task.id,
        title: task.title,
        description: task.description,
      );

factory Task.fromJson(Map<String, dynamic> json) => Task(
      DateTime.parse(json['date']),
      json['isDone'],
      User.fromJson(json['assignee']),
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'isDone': isDone,
      };
}
