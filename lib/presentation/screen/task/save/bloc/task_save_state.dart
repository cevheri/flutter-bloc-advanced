part of 'task_save_bloc.dart';

enum TaskSaveStatus { none, loading, loaded, failure }

class TaskSaveState extends Equatable {
  final int id;
  final String name;
  final int price;
  final TaskSaveStatus status;

  const TaskSaveState({
    this.id = 0,
    this.name = '',
    this.price = 0,
    this.status = TaskSaveStatus.none,
  });

  @override
  List<Object> get props => [id, name, price, status];

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
  bool get stringify => true;
}
