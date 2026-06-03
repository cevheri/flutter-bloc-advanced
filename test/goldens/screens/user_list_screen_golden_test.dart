import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_list_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
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

  late MockUserListBloc userListBloc;
  late MockAuthorityBloc authorityBloc;

  const sampleUsers = [
    UserEntity(
      id: '1',
      login: 'john.doe',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      activated: true,
      authorities: ['ROLE_ADMIN'],
    ),
    UserEntity(
      id: '2',
      login: 'jane.smith',
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane.smith@example.com',
      activated: true,
      authorities: ['ROLE_USER'],
    ),
    UserEntity(
      id: '3',
      login: 'bob.inactive',
      firstName: 'Bob',
      lastName: 'Inactive',
      email: 'bob@example.com',
      activated: false,
      authorities: ['ROLE_USER'],
    ),
  ];

  const loadedState = UserListLoaded(users: sampleUsers);
  const authorityState = AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']);

  setUp(() {
    userListBloc = MockUserListBloc();
    authorityBloc = MockAuthorityBloc();

    whenListen(userListBloc, Stream<UserListState>.empty(), initialState: loadedState);
    when(() => userListBloc.state).thenReturn(loadedState);

    whenListen(authorityBloc, Stream<AuthorityState>.empty(), initialState: authorityState);
    when(() => authorityBloc.state).thenReturn(authorityState);
  });

  Widget buildScreen({bool dark = false}) {
    final router = GoRouter(
      initialLocation: '/user',
      routes: [
        GoRoute(
          name: 'userList',
          path: '/user',
          builder: (context, state) => const Scaffold(body: UserListPage()),
        ),
        GoRoute(
          name: 'userCreate',
          path: '/user/new',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          name: 'userEdit',
          path: '/user/:id/edit',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          name: 'userView',
          path: '/user/:id/view',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserListBloc>.value(value: userListBloc),
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
    'UserListScreen — light',
    fileName: 'user_list_screen_light',
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
    'UserListScreen — dark',
    fileName: 'user_list_screen_dark',
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
