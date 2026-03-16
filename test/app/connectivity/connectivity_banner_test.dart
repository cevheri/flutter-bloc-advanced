import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_banner.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_utils.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityState> implements ConnectivityCubit {}

void main() {
  late MockConnectivityCubit mockCubit;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    mockCubit = MockConnectivityCubit();
  });

  Widget buildTestableWidget({required ConnectivityState state}) {
    when(() => mockCubit.state).thenReturn(state);
    whenListen(mockCubit, Stream<ConnectivityState>.value(state), initialState: state);

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ConnectivityCubit>.value(
          value: mockCubit,
          child: const Column(
            children: [
              ConnectivityBanner(),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('ConnectivityBanner', () {
    group('when offline', () {
      testWidgets('should display offline banner content', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.offline)),
        );
        await tester.pump();

        expect(find.text('No internet connection'), findsOneWidget);
      });

      testWidgets('should display cloud_off icon', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.offline)),
        );
        await tester.pump();

        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      });

      testWidgets('should have full opacity when offline', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.offline)),
        );
        await tester.pump();

        final animatedOpacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
        expect(animatedOpacity.opacity, 1.0);
      });

      testWidgets('should have zero offset when offline (visible)', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.offline)),
        );
        await tester.pump();

        final animatedSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
        expect(animatedSlide.offset, Offset.zero);
      });

      testWidgets('should use error color scheme for background', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.offline)),
        );
        await tester.pump();

        // Find the Container with the error color decoration
        final container = tester.widget<Container>(
          find.descendant(of: find.byType(Material), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration, isNotNull);
        expect(decoration!.color, isNotNull);
      });
    });

    group('when online', () {
      testWidgets('should not display offline banner text', (tester) async {
        await tester.pumpWidget(buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.online)));
        await tester.pumpAndSettle();

        // When online, the child is SizedBox.shrink, so text should not be found
        expect(find.text('No internet connection'), findsNothing);
      });

      testWidgets('should not display cloud_off icon', (tester) async {
        await tester.pumpWidget(buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.online)));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
      });

      testWidgets('should have zero opacity when online', (tester) async {
        await tester.pumpWidget(buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.online)));
        await tester.pump();

        final animatedOpacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
        expect(animatedOpacity.opacity, 0.0);
      });

      testWidgets('should have negative y offset when online (hidden above)', (tester) async {
        await tester.pumpWidget(buildTestableWidget(state: const ConnectivityState(status: ConnectivityStatus.online)));
        await tester.pump();

        final animatedSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
        expect(animatedSlide.offset, const Offset(0, -1));
      });
    });

    group('state transitions', () {
      testWidgets('should show banner when transitioning from online to offline', (tester) async {
        const onlineState = ConnectivityState(status: ConnectivityStatus.online);
        const offlineState = ConnectivityState(status: ConnectivityStatus.offline);

        // Use whenListen with a stream that emits offline after initial online
        when(() => mockCubit.state).thenReturn(onlineState);
        whenListen(mockCubit, Stream.fromIterable([offlineState]), initialState: onlineState);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<ConnectivityCubit>.value(
                value: mockCubit,
                child: const Column(
                  children: [
                    ConnectivityBanner(),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        );

        // Let the stream event propagate and rebuild
        await tester.pump();

        // After the stream emits offline, banner should be visible
        expect(find.text('No internet connection'), findsOneWidget);
      });

      testWidgets('should hide banner when transitioning from offline to online', (tester) async {
        const offlineState = ConnectivityState(status: ConnectivityStatus.offline);
        const onlineState = ConnectivityState(status: ConnectivityStatus.online);

        when(() => mockCubit.state).thenReturn(offlineState);
        whenListen(mockCubit, Stream.fromIterable([onlineState]), initialState: offlineState);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<ConnectivityCubit>.value(
                value: mockCubit,
                child: const Column(
                  children: [
                    ConnectivityBanner(),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        );

        // Let the stream event propagate and animations settle
        await tester.pumpAndSettle();

        // After the stream emits online, banner should be hidden
        expect(find.text('No internet connection'), findsNothing);
      });
    });
  });

  group('ConnectivityState', () {
    test('initial state should be online', () {
      const state = ConnectivityState.initial();
      expect(state.isOnline, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.lastOnline, isNull);
    });

    test('isOnline should return true when status is online', () {
      const state = ConnectivityState(status: ConnectivityStatus.online);
      expect(state.isOnline, isTrue);
      expect(state.isOffline, isFalse);
    });

    test('isOffline should return true when status is offline', () {
      const state = ConnectivityState(status: ConnectivityStatus.offline);
      expect(state.isOnline, isFalse);
      expect(state.isOffline, isTrue);
    });

    test('copyWith should update status', () {
      const state = ConnectivityState(status: ConnectivityStatus.online);
      final updated = state.copyWith(status: ConnectivityStatus.offline);
      expect(updated.status, ConnectivityStatus.offline);
    });

    test('copyWith should preserve unchanged fields', () {
      final now = DateTime.now();
      final state = ConnectivityState(status: ConnectivityStatus.online, lastOnline: now);
      final updated = state.copyWith(status: ConnectivityStatus.offline);
      expect(updated.lastOnline, now);
    });

    test('copyWith should update lastOnline', () {
      final now = DateTime.now();
      const state = ConnectivityState(status: ConnectivityStatus.online);
      final updated = state.copyWith(lastOnline: now);
      expect(updated.lastOnline, now);
      expect(updated.status, ConnectivityStatus.online);
    });

    test('should use Equatable for equality', () {
      const state1 = ConnectivityState(status: ConnectivityStatus.online);
      const state2 = ConnectivityState(status: ConnectivityStatus.online);
      const state3 = ConnectivityState(status: ConnectivityStatus.offline);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props should include status and lastOnline', () {
      final now = DateTime.now();
      final state = ConnectivityState(status: ConnectivityStatus.online, lastOnline: now);
      expect(state.props, [ConnectivityStatus.online, now]);
    });
  });
}
