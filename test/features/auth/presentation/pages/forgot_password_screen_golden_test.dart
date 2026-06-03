import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';
import '../../../../support/golden_app.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockForgotPasswordBloc forgotPasswordBloc;
  late MockAccountBloc accountBloc;

  setUp(() {
    forgotPasswordBloc = MockForgotPasswordBloc();
    accountBloc = MockAccountBloc();

    whenListen(
      forgotPasswordBloc,
      Stream<ForgotPasswordState>.empty(),
      initialState: const ForgotPasswordInitialState(),
    );
    when(() => forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());

    whenListen(accountBloc, Stream<AccountState>.empty(), initialState: const AccountState());
    when(() => accountBloc.state).thenReturn(const AccountState());
  });

  Widget buildScreen({bool dark = false}) {
    final screen = MultiBlocProvider(
      providers: [
        BlocProvider<ForgotPasswordBloc>.value(value: forgotPasswordBloc),
        BlocProvider<AccountBloc>.value(value: accountBloc),
      ],
      child: ForgotPasswordScreen(),
    );
    return goldenScreen(screen, dark: dark);
  }

  goldenTest(
    'ForgotPasswordScreen — light',
    fileName: 'forgot_password_screen_light',
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
    'ForgotPasswordScreen — dark',
    fileName: 'forgot_password_screen_dark',
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
