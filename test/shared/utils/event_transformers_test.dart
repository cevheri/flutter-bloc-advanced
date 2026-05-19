import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Test scaffold ---------------------------------------------------------

abstract class _Event {}

class _Run extends _Event {}

class _CounterBloc extends Bloc<_Event, int> {
  _CounterBloc({required EventTransformer<_Run> transformer}) : super(0) {
    on<_Run>((event, emit) async {
      runs++;
      await Future<void>.delayed(handlerDelay);
      emit(state + 1);
    }, transformer: transformer);
  }

  int runs = 0;

  /// Long enough that two rapid events in a single tick will overlap
  /// without [dropConcurrent]; short enough to keep tests snappy.
  static const Duration handlerDelay = Duration(milliseconds: 80);
}

void main() {
  group('EventTransformers.dropConcurrent', () {
    blocTest<_CounterBloc, int>(
      'a second event added while the first handler is running is dropped',
      build: () => _CounterBloc(transformer: EventTransformers.dropConcurrent()),
      act: (bloc) {
        bloc.add(_Run());
        bloc.add(_Run()); // dropped: previous handler is still running.
      },
      wait: const Duration(milliseconds: 250),
      expect: () => [1],
      verify: (bloc) => expect(bloc.runs, 1),
    );
  });

  group('EventTransformers.debounceRestartable', () {
    blocTest<_CounterBloc, int>(
      'rapid bursts collapse to a single handler invocation after debounce',
      build: () => _CounterBloc(transformer: EventTransformers.debounceRestartable(const Duration(milliseconds: 50))),
      act: (bloc) {
        bloc.add(_Run());
        bloc.add(_Run());
        bloc.add(_Run());
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [1],
      verify: (bloc) => expect(bloc.runs, 1),
    );
  });

  group('EventTransformers.restart', () {
    blocTest<_CounterBloc, int>(
      'a new event cancels the in-flight handler so only the latest emits',
      build: () => _CounterBloc(transformer: EventTransformers.restart()),
      act: (bloc) {
        bloc.add(_Run());
        bloc.add(_Run()); // cancels the prior handler before it emits.
      },
      wait: const Duration(milliseconds: 250),
      // Two handler invocations start, but only the latest reaches emit(): 1.
      expect: () => [1],
    );
  });

  group('EventTransformers.queue', () {
    blocTest<_CounterBloc, int>(
      'events are processed strictly one-at-a-time in arrival order',
      build: () => _CounterBloc(transformer: EventTransformers.queue()),
      act: (bloc) {
        bloc.add(_Run());
        bloc.add(_Run());
        bloc.add(_Run());
      },
      // 3 handlers × 80ms each, run sequentially, so wait > 240ms.
      wait: const Duration(milliseconds: 350),
      // None dropped, none cancelled — three emissions in order.
      expect: () => [1, 2, 3],
      verify: (bloc) => expect(bloc.runs, 3),
    );
  });
}
