import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';
import '../../../../support/golden_app.dart' show kGoldenScreenSize;

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockUserEditorBloc userEditorBloc;
  late MockAuthorityBloc authorityBloc;

  const sampleUser = UserEntity(
    id: 'test-user-1',
    login: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    activated: true,
    authorities: ['ROLE_USER'],
  );

  final loadedState = UserEditorLoaded(data: sampleUser);
  const authorityState = AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']);

  setUp(() {
    userEditorBloc = MockUserEditorBloc();
    authorityBloc = MockAuthorityBloc();

    whenListen(userEditorBloc, Stream<UserEditorState>.empty(), initialState: loadedState);
    when(() => userEditorBloc.state).thenReturn(loadedState);

    whenListen(authorityBloc, Stream<AuthorityState>.empty(), initialState: authorityState);
    when(() => authorityBloc.state).thenReturn(authorityState);
  });

  Widget buildScreen({bool dark = false}) {
    const userId = 'test-user-1';

    final router = GoRouter(
      initialLocation: '/user/$userId/edit',
      routes: [
        GoRoute(
          path: '/user/:id/edit',
          builder: (context, state) => Scaffold(
            body: UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.edit),
          ),
        ),
        GoRoute(
          path: '/user/:id/view',
          builder: (context, state) => Scaffold(
            body: UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.view),
          ),
        ),
        GoRoute(
          path: '/user/new',
          builder: (context, state) => const Scaffold(body: UserEditorPage(mode: EditorFormMode.create)),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserEditorBloc>.value(value: userEditorBloc),
        BlocProvider<AuthorityBloc>.value(value: authorityBloc),
      ],
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
    'UserEditorScreen — light',
    fileName: 'user_editor_screen_light',
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
    'UserEditorScreen — dark',
    fileName: 'user_editor_screen_dark',
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
