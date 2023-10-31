part of 'task_save_bloc.dart';

class TaskSaveEvent extends Equatable {
  const TaskSaveEvent();

  @override
  List<Object> get props => [];
}

class TaskSave extends TaskSaveEvent {
  final int? id;
  final String? name;
  final int? price;

  const TaskSave({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object> get props => [id!, name!, price!];
}

class TaskFormSubmitted extends TaskSaveEvent {}
