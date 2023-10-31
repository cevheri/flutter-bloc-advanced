part of 'task_save_bloc.dart';

class TaskSaveEvent extends Equatable {
  const TaskSaveEvent();

  @override
  List<Object> get props => [];
}

class TaskFormSubmitted extends TaskSaveEvent {
  final int? id;
  final String? name;
  final int? price;
  final BuildContext context;


  const TaskFormSubmitted({
    required this.id,
    required this.name,
    required this.price,
    required this.context,
  });
}
