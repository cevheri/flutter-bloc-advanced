import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';
import '../support/golden_app.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockLoginBloc loginBloc;
  late MockAccountBloc accountBloc;

  setUp(() {
    loginBloc = MockLoginBloc();
    accountBloc = MockAccountBloc();

    whenListen(loginBloc, Stream<LoginState>.empty(), initialState: const LoginInitialState());
    when(() => loginBloc.state).thenReturn(const LoginInitialState());

    whenListen(accountBloc, Stream<AccountState>.empty(), initialState: const AccountState());
    when(() => accountBloc.state).thenReturn(const AccountState());
  });

  Widget buildScreen({bool dark = false}) {
    final screen = MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>.value(value: loginBloc),
        BlocProvider<AccountBloc>.value(value: accountBloc),
      ],
      child: const LoginScreen(),
    );
    return goldenScreen(screen, dark: dark);
  }

  goldenTest(
    'LoginScreen — light',
    fileName: 'login_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'initial',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'LoginScreen — dark',
    fileName: 'login_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'initial',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: true)),
        ),
      ],
    ),
  );
}
