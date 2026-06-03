import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/test_env.dart';
import '../support/golden_app.dart';

class MockSystemDashboardCubit extends MockCubit<SystemDashboardState> implements SystemDashboardCubit {}

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockSystemDashboardCubit dashboardCubit;

  final loadedState = SystemDashboardState(
    status: SystemDashboardStatus.loaded,
    connectivity: ConnectivityStatus.online,
    circuitBreakerTotal: 2,
    circuitBreakerOpen: 0,
    cacheItemCount: 10,
    featureFlagsOn: 1,
    featureFlagsTotal: 3,
    endpointHealthList: const [
      EndpointHealth(endpoint: '/api/users', state: CircuitBreakerState.closed),
      EndpointHealth(endpoint: '/api/auth', state: CircuitBreakerState.closed),
    ],
    featureFlags: const {'darkMode': true, 'beta': false, 'newDashboard': false},
    interceptors: const [
      InterceptorInfo(name: 'AuthInterceptor', order: 1, detail: 'Attaches JWT'),
      InterceptorInfo(name: 'LoggingInterceptor', order: 2, detail: 'Logs requests'),
    ],
  );

  setUp(() {
    dashboardCubit = MockSystemDashboardCubit();

    whenListen(dashboardCubit, Stream<SystemDashboardState>.empty(), initialState: loadedState);
    when(() => dashboardCubit.state).thenReturn(loadedState);
  });

  Widget buildScreen({bool dark = false}) {
    final screen = BlocProvider<SystemDashboardCubit>.value(
      value: dashboardCubit,
      child: const Scaffold(body: DashboardPage()),
    );
    return goldenScreen(screen, dark: dark);
  }

  goldenTest(
    'DashboardScreen — light',
    fileName: 'dashboard_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'DashboardScreen — dark',
    fileName: 'dashboard_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: true)),
        ),
      ],
    ),
  );
}
