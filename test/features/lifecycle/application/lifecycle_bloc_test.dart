import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils.dart';

class MockLifecycleRepository extends Mock implements ILifecycleRepository {}

void main() {
  late MockLifecycleRepository mockRepository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    mockRepository = MockLifecycleRepository();
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

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit [loading, ready] with error message on failure (graceful degradation)',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Failure(NetworkError('No connection')));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [
          const LifecycleLoading(),
          isA<LifecycleReady>().having((s) => s.error, 'error', 'No connection'),
        ],
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
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.0.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready when current version is above minimum version',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '0.9.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should emit ready when minimumVersion is null',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(maintenanceMode: false)));
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
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(maintenanceMode: false, featureFlags: {})));
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
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.0.1', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should handle minor version comparison (1.0.0 < 1.1.0)',
        setUp: () => AppConstants.appVersion = '1.0.0',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.1.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should handle major version comparison (1.9.9 < 2.0.0)',
        setUp: () => AppConstants.appVersion = '1.9.9',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '2.0.0', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleForceUpdate>()],
      );

      blocTest<LifecycleBloc, LifecycleState>(
        'should not force update when current major is higher (2.0.0 > 1.9.9)',
        setUp: () => AppConstants.appVersion = '2.0.0',
        build: () {
          when(
            () => mockRepository.fetchAppConfig(),
          ).thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '1.9.9', maintenanceMode: false)));
          return LifecycleBloc(repository: mockRepository, featureFlagService: FeatureFlagService.instance);
        },
        act: (bloc) => bloc.add(const LifecycleCheckEvent()),
        expect: () => [const LifecycleLoading(), isA<LifecycleReady>()],
      );
    });
  });
}
