import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';

/// Combined BlocObserver that feeds both [DevConsoleStore] and [TimeTravelStore].
///
/// Replaces [DevConsoleBlocObserver] when time-travel is enabled.
/// Install via `Bloc.observer = TimeTravelBlocObserver();` in bootstrap.
class TimeTravelBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (!kDebugMode) return;
    TimeTravelStore.instance.registerBloc(bloc.runtimeType.toString(), bloc);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (!kDebugMode) return;
    TimeTravelStore.instance.unregisterBloc(bloc.runtimeType.toString());
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;

    final blocName = bloc.runtimeType.toString();
    final event = transition.event.toString();
    final currentState = transition.currentState;
    final nextState = transition.nextState;

    // Feed DevConsoleStore (for BLoC tab)
    DevConsoleStore.instance.addBlocTransition(
      BlocTransitionEntry(
        blocName: blocName,
        event: event,
        currentState: _formatState(currentState),
        nextState: _formatState(nextState),
        timestamp: DateTime.now(),
      ),
    );

    // Feed TimeTravelStore (for time-travel tab)
    TimeTravelStore.instance.recordTransition(
      blocName: blocName,
      event: event,
      currentState: currentState,
      nextState: nextState,
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!kDebugMode) return;

    // Cubits emit onChange but not onTransition
    if (bloc is! Bloc) {
      final blocName = bloc.runtimeType.toString();

      DevConsoleStore.instance.addBlocTransition(
        BlocTransitionEntry(
          blocName: blocName,
          event: '(state change)',
          currentState: _formatState(change.currentState),
          nextState: _formatState(change.nextState),
          timestamp: DateTime.now(),
        ),
      );

      TimeTravelStore.instance.recordTransition(
        blocName: blocName,
        event: '(state change)',
        currentState: change.currentState,
        nextState: change.nextState,
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;

    final blocName = bloc.runtimeType.toString();

    DevConsoleStore.instance.addBlocTransition(
      BlocTransitionEntry(
        blocName: blocName,
        event: 'ERROR',
        currentState: bloc.state.toString(),
        nextState: 'Error: $error',
        timestamp: DateTime.now(),
      ),
    );
  }

  String _formatState(dynamic state) {
    final str = state.toString();
    return str.length > 500 ? '${str.substring(0, 500)}...' : str;
  }
}
