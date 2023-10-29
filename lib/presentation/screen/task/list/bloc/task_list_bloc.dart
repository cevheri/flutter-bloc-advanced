import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    on<TaskListLoad>(_onLoad);
  }

  final TaskRepository _taskRepository;

  /// Load the task list.
  FutureOr<void> _onLoad(TaskListLoad event, Emitter<TaskListState> emit) async {
    log('event value: $event, emit $emit');
    log("Tasks list loaded successfully");
  }
}
