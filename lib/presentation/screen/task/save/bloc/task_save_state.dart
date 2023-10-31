part of 'task_save_bloc.dart';

enum TaskSaveStatus { none, loading, loaded, failure }

class TaskSaveState extends Equatable {
  final int? id;
  final String? name;
  final int? price;
  final TaskSaveStatus? status;

  const TaskSaveState({
    this.id,
    this.name,
    this.price,
    this.status = TaskSaveStatus.none,
  });

  TaskSaveState copyWith({
    int? id,
    String? name,
    int? price,
    TaskSaveStatus? status,
  }) {
    return TaskSaveState(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [id!, name!, price!, status!];

  @override
  bool get stringify => true;
}
