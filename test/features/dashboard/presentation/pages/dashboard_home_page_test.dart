@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/usecases/fetch_app_config_usecase.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';

void main() {
  late MockAccountBloc accountBloc;
  late MockSystemDashboardCubit dashboardCubit;
  late MockILifecycleRepository lifecycleRepository;
  late LifecycleBloc lifecycleBloc;

  AppConfigSummary summary(String minimumVersion) => AppConfigSummary(
    currentVersion: AppConstants.appVersion,
    minimumVersion: minimumVersion,
    maintenanceMode: false,
    environment: 'test',
  );

  setUp(() {
    AppConstants.appVersion = '1.0.0';
    accountBloc = MockAccountBloc();
    when(() => accountBloc.state).thenReturn(const AccountState(status: AccountStatus.failure));
    dashboardCubit = MockSystemDashboardCubit();
    when(() => dashboardCubit.state).thenReturn(const SystemDashboardState());
    when(() => dashboardCubit.load()).thenAnswer((_) async {});
    lifecycleRepository = MockILifecycleRepository();
    lifecycleBloc = LifecycleBloc(
      fetchAppConfigUseCase: FetchAppConfigUseCase(lifecycleRepository),
      featureFlagService: FeatureFlagService.instance,
      recheckInterval: Duration.zero,
    );
    addTearDown(lifecycleBloc.close);
  });

  Widget page() => MultiBlocProvider(
    providers: [
      BlocProvider<AccountBloc>.value(value: accountBloc),
      BlocProvider<SystemDashboardCubit>.value(value: dashboardCubit),
      BlocProvider<LifecycleBloc>.value(value: lifecycleBloc),
    ],
    child: const MaterialApp(home: Scaffold(body: DashboardHomePage())),
  );

  Future<void> pumpPage(WidgetTester tester, {AppConfig appConfig = const AppConfig.test()}) async {
    await tester.pumpWidget(RepositoryProvider<AppConfig>.value(value: appConfig, child: page()));
    await tester.pump();
  }

  testWidgets('names the environment of the provided AppConfig', (tester) async {
    await pumpPage(tester, appConfig: const AppConfig.prod());

    verify(
      () => dashboardCubit.updateAppConfig(
        AppConfigSummary(
          currentVersion: AppConstants.appVersion,
          minimumVersion: '-',
          maintenanceMode: false,
          environment: 'prod',
        ),
      ),
    ).called(1);
  });

  // AppScope always provides AppConfig. A missing one is a wiring mistake, so the page must not hide it behind a
  // 'dev' label.
  testWidgets('fails when no AppConfig is provided', (tester) async {
    await tester.pumpWidget(page());
    await tester.pump();

    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });

  testWidgets('shows the app config the lifecycle check found when the page opens', (tester) async {
    when(() => lifecycleRepository.fetchAppConfig())
        .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '0.5.0')));
    lifecycleBloc.add(const LifecycleCheckEvent());
    await tester.runAsync(() => lifecycleBloc.stream.first);

    await pumpPage(tester);

    verify(() => dashboardCubit.updateAppConfig(summary('0.5.0'))).called(1);
  });

  // A resume check that finds a new config goes from LifecycleReady to LifecycleReady. Comparing the state types
  // dropped it, so the dashboard kept showing the config from launch.
  testWidgets('shows the new config a re-check on resume finds while the app stays open', (tester) async {
    when(() => lifecycleRepository.fetchAppConfig())
        .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '0.5.0')));
    lifecycleBloc.add(const LifecycleCheckEvent());
    await tester.runAsync(() => lifecycleBloc.stream.first);
    await pumpPage(tester);

    when(() => lifecycleRepository.fetchAppConfig())
        .thenAnswer((_) async => const Success(AppConfigEntity(minimumVersion: '0.9.0')));
    lifecycleBloc.add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume));
    await tester.runAsync(() => lifecycleBloc.stream.first);
    await tester.pump();

    expect(lifecycleBloc.state, const LifecycleReady(config: AppConfigEntity(minimumVersion: '0.9.0')));
    verify(() => dashboardCubit.updateAppConfig(summary('0.9.0'))).called(1);
  });

  // The dashboard home as the signed-in app shows it at '/', through the real App. These tests lived in
  // home_screen_test.dart, named after a HomeScreen class that no longer exists.
  group('DashboardHomePage in the app', () {
    //region setup
    tearDown(() async {
      TestWidgetsFlutterBinding.instance.reset();
    });

    const language = "en";

    //endregion setup

    // main application unittest end-to-end
    group('opens with a session and without one', () {
      testWidgets("Given valid AccessToken when open home then load ResponsiveScaffold successfully", (tester) async {
        // A desktop surface, where the shell shows the sidebar next to the content.
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        TestEnv.authenticate();

        // Given:
        await tester.pumpWidget(const App(language: language));
        //When:
        await tester.pumpAndSettle();
        //Then:

        // ResponsiveScaffold and shell layout test
        expect(find.byType(ResponsiveScaffold), findsOneWidget);
        expect(find.byType(TopBarWidget), findsOneWidget);
        expect(find.byType(SidebarWidget), findsOneWidget);

        // Dashboard content should be rendered
        expect(find.text('Dashboard'), findsWidgets);

        // Sidebar has logout icon (collapsed sidebar hides labels)
        expect(find.byIcon(Icons.logout), findsWidgets);
      });

      testWidgets("Given an invalid AccessToken when HomeScreen is opened then navigate to loginScreen", (
        tester,
      ) async {
        Widget getWidget() => const App(language: "en");

        // Given:
        await tester.pumpWidget(getWidget());
        //When:
        await tester.pumpAndSettle();
        //Then:
        expect(find.byType(ResponsiveScaffold), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('layout', () {
      // Surfaces where the dashboard overflowed right after login: four KPI columns on a wide screen, and the section
      // titles on a phone. The test font is wider than the real one, which stands in for a larger text scale.
      for (final size in const [
        Size(1366, 768),
        Size(1400, 900),
        Size(1440, 900),
        Size(1366, 1024),
        Size(360, 800),
        Size(390, 844),
        Size(412, 915),
      ]) {
        testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          TestEnv.authenticate();

          await tester.pumpWidget(const App(language: language));
          await tester.pumpAndSettle();

          expect(find.text('Circuit Breaker'), findsOneWidget, reason: 'the loaded dashboard shows its KPI cards');
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
