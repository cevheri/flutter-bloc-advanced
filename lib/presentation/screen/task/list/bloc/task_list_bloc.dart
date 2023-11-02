import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/models/task.dart';
import '../../../../../data/repository/task_repository.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';



/// Bloc responsible for managing the task list.
/// It is used to task list, create, update and delete the task.
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TaskRepository taskRepository,
  })  : _taskRepository = taskRepository,
        super(const TaskListState()) {
    on<TaskListEvent>((event, emit) {});
    on<LoadMoreTasks>(_onLoad);
  }

  final TaskRepository _taskRepository;

  /// Load the task list.
  FutureOr<void> _onLoad(LoadMoreTasks event, Emitter<TaskListState> emit) async {
    log("taskList: onload--------------------------------");
    emit(state.copyWith(status: TaskListStatus.initial));
    try {
      final tasks = await _taskRepository.getTasks();

      if (tasks.isEmpty) {
        log("Task is empty");
        emit(state.copyWith(status: TaskListStatus.failure));
      } else {
        log("Task count: ${tasks.length}");
        emit(state.copyWith(
          tasks: tasks,
          status: TaskListStatus.success,
        ));
      }
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: TaskListStatus.failure));
    }
  }
}
