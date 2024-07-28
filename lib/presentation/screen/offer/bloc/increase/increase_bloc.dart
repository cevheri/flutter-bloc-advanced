import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'increase_event.dart';
part 'increase_state.dart';

class IncreaseBloc extends Bloc<IncreaseEvent, IncreaseState> {
  IncreaseBloc() : super(IncreaseInitial()) {
    on<IncreaseEvent>((event, emit) {});
  }
}
