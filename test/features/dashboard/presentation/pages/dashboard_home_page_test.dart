@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AppConfig>.value(
        value: const AppConfig.test(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountBloc>.value(value: accountBloc),
            BlocProvider<SystemDashboardCubit>.value(value: dashboardCubit),
            BlocProvider<LifecycleBloc>.value(value: lifecycleBloc),
          ],
          child: const MaterialApp(home: Scaffold(body: DashboardHomePage())),
        ),
      ),
    );
    await tester.pump();
  }

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
}
