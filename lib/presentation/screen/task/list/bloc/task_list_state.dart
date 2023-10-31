part of 'task_list_bloc.dart';

enum TaskListStatus { initial, success, failure }

class TaskListState extends Equatable {
  const TaskListState({
    this.status = TaskListStatus.initial,
    this.tasks = const <Task>[],
    this.hasReachedMax = false,
  });

  final List<Task> tasks;
  final TaskListStatus status;
  final bool hasReachedMax;

  TaskListState copyWith({
    TaskListStatus? status,
    List<Task>? tasks,
    bool? hasReachedMax,
  }) {
    return TaskListState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax
    );
  }

  @override
  List<Object> get props => [status, tasks, hasReachedMax];

  @override
  String toString() {
    return 'TaskListState { status: $status, tasks: ${tasks.length}, hasReachedMax: $hasReachedMax }';
  }
}
