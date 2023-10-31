part of 'task_list_bloc.dart';

enum TaskListStatus { initial, success, failure }

class TaskListState extends Equatable {
  const TaskListState({
    this.status = TaskListStatus.initial,
    this.tasks = const <Task>[],
  });

  final List<Task> tasks;
  final TaskListStatus status;

  TaskListState copyWith({
    TaskListStatus? status,
    List<Task>? tasks
  }) {
    return TaskListState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
    );
  }

  @override
  List<Object> get props => [status, tasks];

  @override
  String toString() {
    return 'TaskListState { status: $status, tasks: ${tasks.length} }';
  }
}
