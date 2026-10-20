import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';

void main() {
  late MockILifecycleRepository mockRepository;
  late List<String> errors;

  setUp(() {
    mockRepository = MockILifecycleRepository();
    FeatureFlagService.instance.clear();
    // Set a known appVersion for testing
    AppConstants.appVersion = '1.0.0';
  });

  group('LifecycleBloc', () {
    test('initial state should be LifecycleInitial', () {
      final bloc = LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
      expect(bloc.state, const LifecycleInitial());
      bloc.close();
    });

    group('LifecycleCheckEvent', () {
      blocTest<LifecycleBloc, LifecycleState>(
        'should emit [loading, ready] when config is normal',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer(
            (_) async =>
                const Success(AppConfigEntity(minimumVersion: '0.5.0', latestVersion: '1.0.0', maintenanceMode: false)),
          );
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>().having((s) => s.config, 'config', isNotNull)],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit [loading, maintenance] when maintenanceMode is true',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer(
            (_) async => const Success(AppConfigEntity(maintenanceMode: true, maintenanceMessage: 'Under maintenance')),
          );
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [
          const LifecycleLoading(),
          isA<LifecycleMaintenance>().having(
            (s) => s.config.maintenanceMessage,
            'maintenanceMessage',
            'Under maintenance',
          ),
        ],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit [loading, forceUpdate] when current version is below minimum',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer(
            (_) async =>
                const Success(AppConfigEntity(minimumVersion: '2.0.0', latestVersion: '2.0.0', maintenanceMode: false)),
          );
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [
          const LifecycleLoading(),
          isA<LifecycleForceUpdate>().having((s) => s.config.minimumVersion, 'minimumVersion', '2.0.0'),
        ],
      );

      // The app opens when the config cannot be read (fail open), and the failure is logged as an error with its
      // AppError, code included, instead of a warning with the message alone.
      blocTest<LifecycleBloc, LifecycleState>(
        'opens the app and logs an error when the config cannot be fetched',
        setUp: () => errors = _recordErrors(),
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Failure(NetworkError('No connection')));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), const LifecycleReady(error: NetworkError('No connection'))],
        verify: (_) => expect(errors, contains(allOf(contains('LifecycleBloc : '), contains('No connection')))),
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should prioritize maintenance over force update',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer(
            (_) async => const Success(
              AppConfigEntity(
                minimumVersion: '2.0.0',
                maintenanceMode: true,
                maintenanceMessage: 'Maintenance takes priority',
              ),
            ),
          );
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleMaintenance>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready when current version equals minimum version',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.0.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready when current version is above minimum version',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '0.9.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready when minimumVersion is null',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should update FeatureFlagService when featureFlags are present',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer(
            (_) async => const Success(
              AppConfigEntity(maintenanceMode: false, featureFlags: {'dark_mode': true, 'chat': false}),
            ),
          );
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        verify: (_) {
          expect(FeatureFlagService.instance.isEnabled('dark_mode'), isTrue);
          expect(FeatureFlagService.instance.isEnabled('chat'), isFalse);
        },
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should not update FeatureFlagService when featureFlags are empty',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(maintenanceMode: false, featureFlags: {})));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        verify: (_) {
          expect(FeatureFlagService.instance.allFlags, isEmpty);
        },
      );
    });

    group('LifecycleDismissUpdateEvent', () {
      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready (preserving config) when update is dismissed from force-update',
        build: () => LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance),
        seed: () => const LifecycleForceUpdate(config: AppConfigEntity(minimumVersion: '2.0.0')),
        act: (bloc) => bloc.add(const LifecycleDismissUpdateEvent()),
        expect: () => [isA<LifecycleReady>().having((s) => s.config?.minimumVersion, 'config.minimumVersion', '2.0.0')],
      );
    });

    group('version comparison edge cases', () {
      blocTest<LifecycleBloc, LifecycleState>(
        'should handle patch version comparison (1.0.0 < 1.0.1)',
        setUp: () => AppConstants.appVersion = '1.0.0',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.0.1', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should handle minor version comparison (1.0.0 < 1.1.0)',
        setUp: () => AppConstants.appVersion = '1.0.0',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.1.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should handle major version comparison (1.9.9 < 2.0.0)',
        setUp: () => AppConstants.appVersion = '1.9.9',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '2.0.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should not force update when current major is higher (2.0.0 > 1.9.9)',
        setUp: () => AppConstants.appVersion = '2.0.0',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.9.9', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );
    });

    // A check after the first one keeps the screen the last answer chose until the new answer arrives: emitting
    // LifecycleLoading let the gate show the app between two maintenance answers, and while the user retried.
    group('re-check', () {
      const maintenance = AppConfigEntity(maintenanceMode: true, maintenanceMessage: 'Back soon');
      const updateRequired = AppConfigEntity(minimumVersion: '2.0.0');
      const ready = AppConfigEntity(minimumVersion: '0.5.0');

      blocTest<LifecycleBloc, LifecycleState>(
        'a retry from the maintenance screen shows the check running on that screen, then opens the app',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(ready));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleMaintenance(config: maintenance),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry)),
        expect: () => [
          const LifecycleMaintenance(config: maintenance, checking: true),
          const LifecycleReady(config: ready),
        ],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'a retry that still finds maintenance stops showing the check running',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleMaintenance(config: maintenance),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry)),
        expect: () => [
          const LifecycleMaintenance(config: maintenance, checking: true),
          const LifecycleMaintenance(config: maintenance),
        ],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'a check on resume keeps the update screen until the answer arrives',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(ready));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleForceUpdate(config: updateRequired),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume)),
        expect: () => [const LifecycleReady(config: ready)],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'a check on resume shows nothing until the answer arrives when the app is open',
        build: () {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleReady(config: ready),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume)),
        expect: () => [const LifecycleMaintenance(config: maintenance)],
      );

      // Failing open applies while the app has no answer that blocks it. A failed re-check must not lift a
      // maintenance or update screen the server asked for: a server error or a dropped connection would otherwise
      // let an outdated app in.
      blocTest<LifecycleBloc, LifecycleState>(
        'a failed retry keeps the maintenance screen and logs an error',
        setUp: () => errors = _recordErrors(),
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Failure(ServerError('Server error (503)')));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleMaintenance(config: maintenance),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry)),
        expect: () => [
          const LifecycleMaintenance(config: maintenance, checking: true),
          const LifecycleMaintenance(config: maintenance),
        ],
        verify: (_) => expect(errors, contains(contains('Server error (503)'))),
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'a failed check on resume keeps the update screen and logs an error',
        setUp: () => errors = _recordErrors(),
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Failure(NetworkError('No Internet connection')));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleForceUpdate(config: updateRequired),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume)),
        expect: () => const <LifecycleState>[],
        verify: (_) => expect(errors, contains(contains('No Internet connection'))),
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'a failed check on resume keeps the config the app opened with',
        build: () {
          when(() => mockRepository.fetchAppConfig())
              .thenAnswer((_) async => const Failure(NetworkError('No Internet connection')));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        seed: () => const LifecycleReady(config: ready),
        act: (bloc) => bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume)),
        expect: () => [const LifecycleReady(config: ready, error: NetworkError('No Internet connection'))],
      );
    });

    group('check triggers', () {
      // The bloc reads the time from package:clock, which fakeAsync controls.
      test('checks again on resume only once the recheck interval has passed since the last check', () {
        fakeAsync((async) {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(AppConfigEntity()));
          final bloc = LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
          bloc.add(const LifecycleCheckEvent());
          async.flushMicrotasks();
          verify(() => mockRepository.fetchAppConfig()).called(1);

          async.elapse(LifecycleBloc.defaultRecheckInterval - const Duration(seconds: 1));
          bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume));
          async.flushMicrotasks();
          verifyNever(() => mockRepository.fetchAppConfig());

          async.elapse(const Duration(seconds: 1));
          bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume));
          async.flushMicrotasks();
          verify(() => mockRepository.fetchAppConfig()).called(1);

          bloc.close();
          async.flushMicrotasks();
        });
      });

      test('a retry checks at once, however recent the last check', () {
        fakeAsync((async) {
          when(() => mockRepository.fetchAppConfig()).thenAnswer((_) async => const Success(AppConfigEntity()));
          final bloc = LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
          bloc.add(const LifecycleCheckEvent());
          async.flushMicrotasks();
          bloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry));
          async.flushMicrotasks();

          verify(() => mockRepository.fetchAppConfig()).called(2);
          bloc.close();
          async.flushMicrotasks();
        });
      });

      test('drops a check that arrives while another one is running', () async {
        final answer = Completer<Result<AppConfigEntity>>();
        when(() => mockRepository.fetchAppConfig()).thenAnswer((_) => answer.future);
        final bloc = LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        addTearDown(bloc.close);

        bloc
          ..add(const LifecycleCheckEvent())
          ..add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry));
        await pumpEventQueue();
        answer.complete(const Success(AppConfigEntity()));
        await pumpEventQueue();

        verify(() => mockRepository.fetchAppConfig()).called(1);
        expect(bloc.state, const LifecycleReady(config: AppConfigEntity()));
      });
    });
  });
}

/// Collects the lines the loggers print at error level until the test ends.
List<String> _recordErrors() {
  final lines = <String>[];
  void record(OutputEvent event) {
    if (event.level == Level.error) lines.addAll(event.lines);
  }

  Logger.addOutputListener(record);
  addTearDown(() => Logger.removeOutputListener(record));
  return lines;
}
