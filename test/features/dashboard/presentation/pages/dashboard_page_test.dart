@Tags(['widget'])
library;

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

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockSystemDashboardCubit extends MockCubit<SystemDashboardState> implements SystemDashboardCubit {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildTestWidget(SystemDashboardCubit cubit, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.light,
    locale: locale,
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

  setUp(() {
    cubit = MockSystemDashboardCubit();
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
      when(() => cubit.state)
          .thenReturn(const SystemDashboardState(status: SystemDashboardStatus.error, errorMessage: 'Something broke'));
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

    // The test font is wider than the real one, so with a larger text scale every card title is wider than a phone's
    // card.
    testWidgets('wraps the card titles instead of overflowing on a phone with larger text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      when(() => cubit.state).thenReturn(
        SystemDashboardState(
          status: SystemDashboardStatus.loaded,
          endpointHealthList: const [EndpointHealth(endpoint: '/api/users', state: CircuitBreakerState.closed)],
          featureFlags: const {'darkMode': true},
          interceptors: const [InterceptorInfo(name: 'AuthInterceptor', order: 1, detail: 'Attaches JWT')],
        ),
      );

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
  group('DashboardPage - language', () {
    SystemDashboardState loaded({int total = 2, int cached = 10}) => SystemDashboardState(
      status: SystemDashboardStatus.loaded,
      connectivity: ConnectivityStatus.online,
      circuitBreakerTotal: total,
      circuitBreakerOpen: 0,
      cacheItemCount: cached,
      featureFlagsOn: 1,
      featureFlagsTotal: 3,
      endpointHealthList: const [EndpointHealth(endpoint: '/api/users', state: CircuitBreakerState.closed)],
      featureFlags: const {'darkMode': true, 'beta': false},
      interceptors: const [InterceptorInfo(name: 'AuthInterceptor', order: 1, detail: 'Attaches JWT')],
    );

    void useTallDesktop(WidgetTester tester) {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('shows the loaded dashboard in Turkish', (tester) async {
      useTallDesktop(tester);
      when(() => cubit.state).thenReturn(loaded());

      await tester.pumpWidget(_buildTestWidget(cubit, locale: const Locale('tr')));
      await tester.pumpAndSettle();

      for (final text in [
        'Sistem Paneli',
        'Bağlantı',
        'Çevrimiçi',
        'Devre Kesici',
        '2 uç nokta',
        '0 açık',
        'Önbellek',
        'Önbellekte 10 öğe',
        '1/3 etkin',
        'Devre Kesici Durumu',
        'Hata: 0',
        'Uygulama Yapılandırması',
        'Mevcut Sürüm',
        'En Düşük Sürüm',
        'Bakım Modu',
        'KAPALI',
        'Ortam',
        'Interceptor Zinciri',
        'Hızlı İşlemler',
        'Önbelleği Temizle',
        'Devre Kesicileri Sıfırla',
        'Dinamik Formları Aç',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Özellik Bayrakları'), findsNWidgets(2));
      expect(find.byTooltip('Yenile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty sections in Turkish', (tester) async {
      useTallDesktop(tester);
      when(() => cubit.state).thenReturn(const SystemDashboardState(status: SystemDashboardStatus.loaded));

      await tester.pumpWidget(_buildTestWidget(cubit, locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text('Henüz izlenen uç nokta yok'), findsOneWidget);
      expect(find.text('Yapılandırılmış özellik bayrağı yok'), findsOneWidget);
    });

    testWidgets('shows the error state and its retry button in Turkish', (tester) async {
      when(() => cubit.state)
          .thenReturn(const SystemDashboardState(status: SystemDashboardStatus.error, errorMessage: 'Something broke'));

      await tester.pumpWidget(_buildTestWidget(cubit, locale: const Locale('tr')));
      await tester.pump();

      expect(find.text('Panel Hatası'), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('counts one endpoint and one cached item in the singular in English', (tester) async {
      useTallDesktop(tester);
      when(() => cubit.state).thenReturn(loaded(total: 1, cached: 1));

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('1 endpoint'), findsOneWidget);
      expect(find.text('1 item cached'), findsOneWidget);
    });

    // The names of the circuit breaker states and the interceptor descriptions showed in English, as the code names
    // them, in every language.
    SystemDashboardState withChain() => loaded().copyWith(
      endpointHealthList: const [
        EndpointHealth(endpoint: '/api/users', state: CircuitBreakerState.closed),
        EndpointHealth(endpoint: '/api/auth', state: CircuitBreakerState.halfOpen),
        EndpointHealth(endpoint: '/api/files', state: CircuitBreakerState.open),
      ],
      interceptors: const [
        InterceptorInfo(name: 'ConnectivityInterceptor', order: 1, detail: 'Rejects requests when offline'),
        InterceptorInfo(name: 'AuthInterceptor', order: 2, detail: 'Attaches JWT token to requests'),
        InterceptorInfo(name: 'TokenRefreshInterceptor', order: 3, detail: 'Refreshes expired access tokens'),
        InterceptorInfo(name: 'IdempotencyInterceptor', order: 4, detail: 'Opt-in Idempotency-Key for POST/PUT/PATCH'),
        InterceptorInfo(name: 'ResilienceInterceptor', order: 5, detail: 'Retry + circuit breaker'),
        InterceptorInfo(name: 'CacheInterceptor', order: 6, detail: 'GET response caching with TTL'),
        InterceptorInfo(name: 'DevConsoleInterceptor', order: 7, detail: 'Records requests in dev console'),
        InterceptorInfo(name: 'LoggingInterceptor', order: 8, detail: 'Structured request/response logging'),
        InterceptorInfo(name: 'MockInterceptor', order: 9, detail: 'Serves mock data in dev/test'),
        InterceptorInfo(name: 'TracingInterceptor', order: 10, detail: 'Adds a trace header'),
      ],
    );

    testWidgets('names the circuit breaker states and describes the interceptors in Turkish', (tester) async {
      useTallDesktop(tester);
      when(() => cubit.state).thenReturn(withChain());

      await tester.pumpWidget(_buildTestWidget(cubit, locale: const Locale('tr')));
      await tester.pumpAndSettle();

      for (final text in [
        'Kapalı',
        'Yarı açık',
        'Açık',
        'Çevrimdışıyken istekleri reddeder',
        'İsteklere JWT belirtecini ekler',
        'Süresi dolan erişim belirteçlerini yeniler',
        'POST/PUT/PATCH için isteğe bağlı Idempotency-Key',
        'Yeniden deneme ve devre kesici',
        'GET yanıtlarını süreli önbelleğe alır',
        'İstekleri geliştirici konsoluna kaydeder',
        'Yapılandırılmış istek ve yanıt günlüğü',
        'Geliştirme ve testte sahte veri sunar',
        // An interceptor the dashboard has no text for keeps the description the app gives it.
        'Adds a trace header',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final raw in ['closed', 'halfOpen', 'open', 'Rejects requests when offline']) {
        expect(find.text(raw), findsNothing, reason: raw);
      }
    });

    testWidgets('names the circuit breaker states in English', (tester) async {
      useTallDesktop(tester);
      when(() => cubit.state).thenReturn(withChain());

      await tester.pumpWidget(_buildTestWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Half-open'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Attaches JWT token to requests'), findsOneWidget);
    });
  });
}
