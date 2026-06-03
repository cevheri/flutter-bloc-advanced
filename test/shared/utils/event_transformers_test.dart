import 'package:fake_async/fake_async.dart';
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
    test('a second event added while the first handler is running is dropped', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.dropConcurrent());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run()); // dropped: previous handler is still running.

        async.elapse(const Duration(seconds: 1));

        expect(states, [1]);
        expect(bloc.runs, 1);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.debounceRestartable', () {
    test('rapid bursts collapse to a single handler invocation after debounce', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.debounceRestartable(const Duration(milliseconds: 50)));
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run())
          ..add(_Run());

        async.elapse(const Duration(seconds: 1));

        expect(states, [1]);
        expect(bloc.runs, 1);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.restart', () {
    test('a new event cancels the in-flight handler so only the latest emits', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.restart());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run()); // cancels the prior handler before it emits.

        async.elapse(const Duration(seconds: 1));

        expect(states, [1]);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.queue', () {
    test('events are processed strictly one-at-a-time in arrival order', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.queue());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run())
          ..add(_Run());

        async.elapse(const Duration(seconds: 1));

        expect(states, [1, 2, 3]);
        expect(bloc.runs, 3);

        sub.cancel();
        bloc.close();
      });
    });
  });
}
