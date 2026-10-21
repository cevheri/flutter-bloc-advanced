import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';
import '../../../../support/golden_app.dart';

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

  Widget buildScreen({bool dark = false, AuthMode authMode = const JwtAuthMode()}) {
    final screen = MultiBlocProvider(
      providers: [
        RepositoryProvider<AuthMode>.value(value: authMode),
        BlocProvider<LoginBloc>.value(value: loginBloc),
        BlocProvider<AccountBloc>.value(value: accountBloc),
        // A project that gives all its links, so the page shows its community section.
        RepositoryProvider<ProjectLinks>.value(
          value: const ProjectLinks(
            repository: 'https://github.com/acme/dashboard',
            docs: 'https://docs.acme.example',
            sponsor: 'https://github.com/sponsors/acme',
          ),
        ),
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

  // The single sign-on page of an oidc build, which sends the user to the provider only on a tap. Pumped past the
  // page's 600 ms fade-in, which the first frame of the images above shows blank, so the image shows the form.
  goldenTest(
    'LoginScreen — single sign-on, light',
    fileName: 'login_screen_sso_light',
    pumpBeforeTest: (tester) => tester.pump(const Duration(milliseconds: 600)),
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'initial',
          child: SizedBox.fromSize(
            size: kGoldenScreenSize,
            child: buildScreen(
              authMode: OidcAuthMode(OidcSettings(issuer: Uri.parse('https://id.example.com'), clientId: 'app')),
            ),
          ),
        ),
      ],
    ),
  );
}
