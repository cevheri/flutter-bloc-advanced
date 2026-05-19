import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Project-wide reusable [EventTransformer]s.
///
/// Picking a transformer is part of designing an event — search inputs need
/// debouncing + restart-on-new-input, write actions need drop-while-running
/// to defeat double-submits, and pagination needs strict serial ordering so
/// page N+1 never beats page N. The defaults below encode those policies so
/// every BLoC reaches for the same names.
///
/// Naming follows the bloc_concurrency conventions:
/// - `restartable`: cancel in-flight, run the new event (switchMap).
/// - `droppable`: ignore new events while one is in flight (exhaustMap).
/// - `sequential`: queue and run one at a time (concatMap).
class EventTransformers {
  EventTransformers._();

  /// Default debounce window for user-typed search inputs. Tuned for a
  /// "feels instant but doesn't fire on every keystroke" UX.
  static const Duration defaultDebounce = Duration(milliseconds: 300);

  /// Debounce + restartable: the right shape for search-as-you-type. Each
  /// new event waits [duration] to see if more events arrive; once it
  /// fires, any still-running handler is cancelled in favor of the latest.
  /// Result: at most one in-flight search, always for the latest query.
  static EventTransformer<E> debounceRestartable<E>([Duration duration = defaultDebounce]) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  /// Re-export of bloc_concurrency's [droppable] under our naming so all
  /// transformers are reached via [EventTransformers]. Use for submit /
  /// delete / write events to prevent concurrent re-execution.
  static EventTransformer<E> dropConcurrent<E>() => droppable<E>();

  /// Re-export of bloc_concurrency's [restartable]. Use for pure read
  /// actions where only the latest matters (e.g. AuthorityLoad).
  static EventTransformer<E> restart<E>() => restartable<E>();

  /// Re-export of bloc_concurrency's [sequential]. Use when handler order
  /// must equal event order (e.g. pagination, ordered mutations).
  static EventTransformer<E> queue<E>() => sequential<E>();
}
