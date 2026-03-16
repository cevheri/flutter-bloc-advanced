import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';

/// BlocObserver that automatically logs BLoC transitions to an analytics service.
///
/// This is a composable observer — it delegates to an [IAnalyticsService]
/// and can be combined with other observers (DevConsole, TimeTravel) via a
/// multi-observer wrapper or by chaining within a single observer.
class AnalyticsBlocObserver extends BlocObserver {
  AnalyticsBlocObserver(this._analytics);

  final IAnalyticsService _analytics;

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _analytics.logEvent(
      name: 'bloc_transition',
      parameters: {
        'bloc': bloc.runtimeType.toString(),
        'event': transition.event.runtimeType.toString(),
        'from': transition.currentState.runtimeType.toString(),
        'to': transition.nextState.runtimeType.toString(),
      },
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _analytics.logError(error: error, stackTrace: stackTrace, reason: '${bloc.runtimeType} error');
  }
}
