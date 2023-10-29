part of 'task_list_bloc.dart';

enum TaskListStatus { initial, loading, loaded }

class TaskListState extends Equatable {
  final String name;
  final int price;

  /// Default constructor for this class
  const TaskListState({
    this.name = '',
    this.price = 0,
  });

  TaskListState copyWith({
    String? name,
    int? price,
  }) {
    return TaskListState(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  @override
  List<Object> get props => [name, price];

  @override
  bool get stringify => true;
}
