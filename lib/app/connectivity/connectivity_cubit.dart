import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';

/// State representing the current connectivity status.
class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  final DateTime? lastOnline;

  const ConnectivityState({required this.status, this.lastOnline});

  const ConnectivityState.initial() : status = ConnectivityStatus.online, lastOnline = null;

  ConnectivityState copyWith({ConnectivityStatus? status, DateTime? lastOnline}) {
    return ConnectivityState(status: status ?? this.status, lastOnline: lastOnline ?? this.lastOnline);
  }

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  @override
  List<Object?> get props => [status, lastOnline];
}

/// App-level cubit that listens to [ConnectivityService] and emits
/// [ConnectivityState] changes.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit() : super(const ConnectivityState.initial());

  StreamSubscription<ConnectivityStatus>? _subscription;

  /// Start listening to connectivity changes from the service.
  void monitor() {
    // Set initial state from service
    final currentStatus = ConnectivityService.instance.currentStatus;
    emit(
      ConnectivityState(
        status: currentStatus,
        lastOnline: currentStatus == ConnectivityStatus.online ? DateTime.now() : null,
      ),
    );

    _subscription = ConnectivityService.instance.statusStream.listen(_onStatusChanged);
  }

  void _onStatusChanged(ConnectivityStatus status) {
    final DateTime? lastOnline;
    if (status == ConnectivityStatus.online) {
      lastOnline = DateTime.now();
    } else {
      // Keep the previous lastOnline timestamp when going offline
      lastOnline = state.isOnline ? DateTime.now() : state.lastOnline;
    }

    emit(ConnectivityState(status: status, lastOnline: lastOnline));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
