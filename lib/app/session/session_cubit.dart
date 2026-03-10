import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/security/security_utils.dart';

class SessionState extends Equatable {
  const SessionState({required this.isAuthenticated});

  const SessionState.unknown() : isAuthenticated = false;

  final bool isAuthenticated;

  SessionState copyWith({bool? isAuthenticated}) {
    return SessionState(isAuthenticated: isAuthenticated ?? this.isAuthenticated);
  }

  @override
  List<Object?> get props => [isAuthenticated];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const SessionState.unknown());

  void restore() {
    emit(SessionState(isAuthenticated: SecurityUtils.isUserLoggedIn()));
  }

  void markAuthenticated() {
    emit(const SessionState(isAuthenticated: true));
  }

  void markLoggedOut() {
    emit(const SessionState(isAuthenticated: false));
  }

  void refresh() {
    restore();
  }
}
