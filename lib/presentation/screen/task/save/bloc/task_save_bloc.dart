import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/routes.dart';
import 'package:flutter_bloc_advance/data/repository/task_repository.dart';

import '../../../../../data/models/task.dart';

part 'task_save_event.dart';
part 'task_save_state.dart';

/// Bloc responsible for managing the task save.
/// It is used to create and update the task.
class TaskSaveBloc extends Bloc<TaskSaveEvent, TaskSaveState> {
  TaskSaveBloc({
    required TaskRepository taskRepository
  }) : _taskRepository = taskRepository,
        super(const TaskSaveState()) {
    on<TaskSaveEvent>((event, emit) {});
    on<TaskFormSubmitted>(_onSubmit);
  }

  final TaskRepository _taskRepository;

  /// Save and update the task.
  FutureOr<void> _onSubmit(TaskFormSubmitted event, Emitter<TaskSaveState> emit) async {
    emit(state.copyWith(status: TaskSaveStatus.loading));
    try {
      Task task = Task(
        id: event.id,
        name: event.name,
        price: event.price,
      );
      await _taskRepository.createTask(task).then((value) => {
        Navigator.pushNamed(event.context, ApplicationRoutes.tasks)
      });
      emit(state.copyWith(status: TaskSaveStatus.loaded));
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: TaskSaveStatus.failure));
    }
  }
}
