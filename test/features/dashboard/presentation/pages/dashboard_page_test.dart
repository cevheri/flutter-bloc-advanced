import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockSystemDashboardCubit extends MockCubit<SystemDashboardState> implements SystemDashboardCubit {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildTestWidget(SystemDashboardCubit cubit) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.light,
    locale: const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: BlocProvider<SystemDashboardCubit>.value(
      value: cubit,
      child: const Scaffold(body: DashboardPage()),
    ),
  );
}

void main() {
  late MockSystemDashboardCubit cubit;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    cubit = MockSystemDashboardCubit();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('DashboardPage', () {
    testWidgets('shows skeleton when status is loading', (tester) async {
      when(() => cubit.state).thenReturn(const SystemDashboardState(status: SystemDashboardStatus.loading));

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      // The skeleton is rendered (SingleChildScrollView with shimmer placeholders).
      // Verify that the loaded content is NOT present.
      expect(find.text('System Dashboard'), findsNothing);
    });

    testWidgets('shows error state with retry button when status is error', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const SystemDashboardState(status: SystemDashboardStatus.error, errorMessage: 'Something broke'));
      when(() => cubit.load()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pump();

      expect(find.text('Dashboard Error'), findsOneWidget);
      expect(find.text('Something broke'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pump();
      verify(() => cubit.load()).called(1);
    });

    testWidgets('renders dashboard sections when status is loaded', (tester) async {
      when(() => cubit.state).thenReturn(
        SystemDashboardState(
          status: SystemDashboardStatus.loaded,
          connectivity: ConnectivityStatus.online,
          circuitBreakerTotal: 2,
          circuitBreakerOpen: 0,
          cacheItemCount: 10,
          featureFlagsOn: 1,
          featureFlagsTotal: 3,
          endpointHealthList: const [EndpointHealth(endpoint: '/api/users', state: CircuitBreakerState.closed)],
          featureFlags: const {'darkMode': true, 'beta': false},
          interceptors: const [InterceptorInfo(name: 'AuthInterceptor', order: 1, detail: 'Attaches JWT')],
        ),
      );
      when(() => cubit.load()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('System Dashboard'), findsOneWidget);

      // KPI cards content
      expect(find.text('Connectivity'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Circuit Breaker'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('Feature Flags'), findsWidgets);

      // Circuit breaker health section
      expect(find.text('Circuit Breaker Health'), findsOneWidget);
      expect(find.text('/api/users'), findsOneWidget);

      // Feature flags section
      expect(find.text('darkMode'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);

      // Interceptor chain section
      expect(find.text('Interceptor Chain'), findsOneWidget);
      expect(find.text('AuthInterceptor'), findsOneWidget);

      // Quick actions section
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Reset Circuit Breakers'), findsOneWidget);
    });
  });
}
