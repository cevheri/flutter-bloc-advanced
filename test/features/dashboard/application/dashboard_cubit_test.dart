import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockFeatureFlagService extends Mock implements FeatureFlagService {}

class MockResilienceInterceptor extends Mock implements ResilienceInterceptor {}

class MockSharedPrefsCacheStorage extends Mock implements SharedPrefsCacheStorage {}

void main() {
  late MockConnectivityService connectivityService;
  late MockFeatureFlagService featureFlagService;
  late MockResilienceInterceptor resilienceInterceptor;
  late MockSharedPrefsCacheStorage cacheStorage;
  late StreamController<ConnectivityStatus> connectivityController;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    connectivityService = MockConnectivityService();
    featureFlagService = MockFeatureFlagService();
    resilienceInterceptor = MockResilienceInterceptor();
    cacheStorage = MockSharedPrefsCacheStorage();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();

    when(() => connectivityService.statusStream).thenAnswer((_) => connectivityController.stream);
    when(() => connectivityService.currentStatus).thenReturn(ConnectivityStatus.online);
    when(() => featureFlagService.addListener(any())).thenReturn(null);
    when(() => featureFlagService.removeListener(any())).thenReturn(null);
    when(() => featureFlagService.allFlags).thenReturn({});
    when(() => resilienceInterceptor.circuitBreakers).thenReturn({});
    when(() => cacheStorage.count()).thenAnswer((_) async => 0);
  });

  tearDown(() async {
    await connectivityController.close();
    await TestUtils().tearDownUnitTest();
  });

  SystemDashboardCubit buildCubit() {
    return SystemDashboardCubit(
      connectivityService: connectivityService,
      featureFlagService: featureFlagService,
      resilienceInterceptor: resilienceInterceptor,
      cacheStorage: cacheStorage,
    );
  }

  group('SystemDashboardCubit', () {
    test('initial state has status initial', () {
      final cubit = buildCubit();
      expect(cubit.state.status, SystemDashboardStatus.initial);
      cubit.close();
    });

    // -----------------------------------------------------------------------
    // load()
    // -----------------------------------------------------------------------

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'load() emits [loading, loaded] with metrics',
      setUp: () {
        when(() => connectivityService.currentStatus).thenReturn(ConnectivityStatus.online);
        when(() => resilienceInterceptor.circuitBreakers).thenReturn({});
        when(() => cacheStorage.count()).thenAnswer((_) async => 5);
        when(() => featureFlagService.allFlags).thenReturn({'darkMode': true, 'beta': false});
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SystemDashboardState>().having((s) => s.status, 'status', SystemDashboardStatus.loading),
        isA<SystemDashboardState>()
            .having((s) => s.status, 'status', SystemDashboardStatus.loaded)
            .having((s) => s.connectivity, 'connectivity', ConnectivityStatus.online)
            .having((s) => s.cacheItemCount, 'cacheItemCount', 5)
            .having((s) => s.featureFlagsTotal, 'featureFlagsTotal', 2)
            .having((s) => s.featureFlagsOn, 'featureFlagsOn', 1),
      ],
    );

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'load() emits [loading, error] when an exception is thrown',
      setUp: () {
        when(() => cacheStorage.count()).thenThrow(Exception('cache error'));
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SystemDashboardState>().having((s) => s.status, 'status', SystemDashboardStatus.loading),
        isA<SystemDashboardState>()
            .having((s) => s.status, 'status', SystemDashboardStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('cache error')),
      ],
    );

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'load() includes circuit breaker endpoint health',
      setUp: () {
        final breaker = CircuitBreaker();
        when(() => resilienceInterceptor.circuitBreakers).thenReturn({'/api/users': breaker});
        when(() => cacheStorage.count()).thenAnswer((_) async => 0);
        when(() => featureFlagService.allFlags).thenReturn({});
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<SystemDashboardState>().having((s) => s.status, 'status', SystemDashboardStatus.loading),
        isA<SystemDashboardState>()
            .having((s) => s.status, 'status', SystemDashboardStatus.loaded)
            .having((s) => s.circuitBreakerTotal, 'circuitBreakerTotal', 1)
            .having((s) => s.endpointHealthList.length, 'endpointHealthList.length', 1),
      ],
    );

    // -----------------------------------------------------------------------
    // updateAppConfig()
    // -----------------------------------------------------------------------

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'updateAppConfig() emits updated appConfig',
      build: buildCubit,
      act: (cubit) => cubit.updateAppConfig(
        const AppConfigSummary(currentVersion: '1.0.0', minimumVersion: '0.9.0', environment: 'prod'),
      ),
      expect: () => [
        isA<SystemDashboardState>()
            .having((s) => s.appConfig.currentVersion, 'currentVersion', '1.0.0')
            .having((s) => s.appConfig.environment, 'environment', 'prod'),
      ],
    );

    // -----------------------------------------------------------------------
    // toggleFeatureFlag()
    // -----------------------------------------------------------------------

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'toggleFeatureFlag() delegates to FeatureFlagService.setFlag',
      setUp: () {
        when(() => featureFlagService.setFlag('darkMode', true)).thenReturn(null);
      },
      build: buildCubit,
      act: (cubit) => cubit.toggleFeatureFlag('darkMode', true),
      verify: (_) {
        verify(() => featureFlagService.setFlag('darkMode', true)).called(1);
      },
    );

    // -----------------------------------------------------------------------
    // clearCache()
    // -----------------------------------------------------------------------

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'clearCache() clears storage then reloads',
      setUp: () {
        when(() => cacheStorage.clear()).thenAnswer((_) async {});
        when(() => cacheStorage.count()).thenAnswer((_) async => 0);
        when(() => featureFlagService.allFlags).thenReturn({});
      },
      build: buildCubit,
      act: (cubit) => cubit.clearCache(),
      verify: (_) {
        verify(() => cacheStorage.clear()).called(1);
        // load() is called internally after clear
        verify(() => cacheStorage.count()).called(1);
      },
    );

    // -----------------------------------------------------------------------
    // resetCircuitBreakers()
    // -----------------------------------------------------------------------

    blocTest<SystemDashboardCubit, SystemDashboardState>(
      'resetCircuitBreakers() resets all breakers then reloads',
      setUp: () {
        when(() => resilienceInterceptor.resetAll()).thenReturn(null);
        when(() => cacheStorage.count()).thenAnswer((_) async => 0);
        when(() => featureFlagService.allFlags).thenReturn({});
      },
      build: buildCubit,
      act: (cubit) => cubit.resetCircuitBreakers(),
      verify: (_) {
        verify(() => resilienceInterceptor.resetAll()).called(1);
      },
    );
  });
}
