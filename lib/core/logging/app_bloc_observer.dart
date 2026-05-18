import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Central [BlocObserver] that routes BLoC lifecycle events through
/// [AppLogger].
///
/// Logs only runtime types (not stringified content) to avoid leaking
/// sensitive fields like passwords or tokens that may be carried on
/// events or held in states with `stringify = true`. BLoCs that need
/// to log specific content should do so explicitly inside their event
/// handlers with whitelisted fields.
///
/// Install once at app startup via `Bloc.observer = AppBlocObserver()`.
/// Other observers (e.g. dev console, analytics) can extend this class
/// to inherit logging while adding their own behaviour.
class AppBlocObserver extends BlocObserver {
  static final _log = AppLogger.getLogger('Bloc');

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log.trace('onCreate: {}', [bloc.runtimeType]);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log.trace('onTransition: {} | event={} | {} -> {}', [
      bloc.runtimeType,
      transition.event.runtimeType,
      transition.currentState.runtimeType,
      transition.nextState.runtimeType,
    ]);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log.trace('onChange: {} | {} -> {}', [
      bloc.runtimeType,
      change.currentState.runtimeType,
      change.nextState.runtimeType,
    ]);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _log.error('onError: {} | {}', [bloc.runtimeType, error]);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log.trace('onClose: {}', [bloc.runtimeType]);
  }
}
