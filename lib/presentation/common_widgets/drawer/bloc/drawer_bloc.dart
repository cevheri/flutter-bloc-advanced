import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repository/login_repository.dart';

part 'drawer_event.dart';

part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final LoginRepository _loginRepository;

  DrawerBloc({
    required LoginRepository loginRepository,
  })  : _loginRepository = loginRepository,
        super(const DrawerState()) {
    on<Logout>(_onLogout);
  }

  FutureOr<void> _onLogout(Logout event, Emitter<DrawerState> emit) async {
    log("DrawerBloc start _onLogout");
    try {
      await _loginRepository.logout();
      emit(state.copyWith(isLogout: true));
      log("DrawerBloc end _onLogout");
    } catch (e) {
      log("DrawerBloc _onLogout error: $e");
    }
  }
}
