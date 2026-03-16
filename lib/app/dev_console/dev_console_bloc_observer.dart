import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';

/// BlocObserver that records every state transition to [DevConsoleStore].
///
/// Only active in debug mode — production builds skip entirely.
/// Install via `Bloc.observer = DevConsoleBlocObserver();` in bootstrap.
class DevConsoleBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;

    DevConsoleStore.instance.addBlocTransition(
      BlocTransitionEntry(
        blocName: bloc.runtimeType.toString(),
        event: transition.event.toString(),
        currentState: _formatState(transition.currentState),
        nextState: _formatState(transition.nextState),
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!kDebugMode) return;

    // Cubits emit onChange but not onTransition
    if (bloc is! Bloc) {
      DevConsoleStore.instance.addBlocTransition(
        BlocTransitionEntry(
          blocName: bloc.runtimeType.toString(),
          event: '(state change)',
          currentState: _formatState(change.currentState),
          nextState: _formatState(change.nextState),
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;

    DevConsoleStore.instance.addBlocTransition(
      BlocTransitionEntry(
        blocName: bloc.runtimeType.toString(),
        event: 'ERROR',
        currentState: bloc.state.toString(),
        nextState: 'Error: $error',
        timestamp: DateTime.now(),
      ),
    );
  }

  String _formatState(dynamic state) {
    final str = state.toString();
    // Trim very long state strings for readability
    return str.length > 500 ? '${str.substring(0, 500)}...' : str;
  }
}
