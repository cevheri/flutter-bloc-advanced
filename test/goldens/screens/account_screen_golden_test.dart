import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';
import '../support/golden_app.dart' show kGoldenScreenSize;

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockAccountBloc accountBloc;

  const sampleUser = UserEntity(
    id: 'test-1',
    login: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    activated: true,
  );

  const loadedState = AccountState(status: AccountStatus.success, data: sampleUser);

  setUp(() {
    accountBloc = MockAccountBloc();

    whenListen(accountBloc, Stream<AccountState>.empty(), initialState: loadedState);
    when(() => accountBloc.state).thenReturn(loadedState);
  });

  Widget buildScreen({bool dark = false}) {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => Scaffold(body: AccountScreen()),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return BlocProvider<AccountBloc>.value(
      value: accountBloc,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
  }

  goldenTest(
    'AccountScreen — light',
    fileName: 'account_screen_light',
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
    'AccountScreen — dark',
    fileName: 'account_screen_dark',
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
