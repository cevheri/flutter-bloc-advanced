@Tags(['widget'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_list_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/fake_data.dart';
import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';

void main() {
  late MockAuthorityBloc mockAuthorityBloc;
  late MockUserListBloc mockUserBloc;

  setUp(() async {
    mockUserBloc = MockUserListBloc();
    mockAuthorityBloc = MockAuthorityBloc();

    // Set up default AuthorityBloc behavior
    when(() => mockAuthorityBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      ]),
    );
    when(() => mockAuthorityBloc.state)
        .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
  });

  Widget buildTestableWidget() {
    final routes = [
      GoRoute(
        name: 'userList',
        path: '/user',
        builder: (context, state) => const Scaffold(body: UserListPage()),
      ),
      GoRoute(
        name: 'userCreate',
        path: '/user/new',
        builder: (context, state) => const Scaffold(body: Text('create-route')),
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
    ];

    final router = GoRouter(initialLocation: '/user', routes: routes);

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserListBloc>.value(value: mockUserBloc),
        BlocProvider<AuthorityBloc>.value(value: mockAuthorityBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }

  group('UserListScreen Tests', () {
    testWidgets('renders the user list correctly', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final userStateController = StreamController<UserListState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserListInitial());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ASSERT - desktop view: search fields + buttons
      expect(find.byType(FormBuilderTextField), findsNWidgets(3));
      expect(find.byKey(const Key('listUserSubmitButtonKey')), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text(S.current.list), findsOneWidget);

      // Check table headers
      expect(find.text(S.current.role), findsOneWidget);
      expect(find.text(S.current.login), findsOneWidget);
      expect(find.text(S.current.first_name), findsOneWidget);
      expect(find.text(S.current.last_name), findsOneWidget);
      expect(find.text(S.current.email), findsOneWidget);
      expect(find.text(S.current.active), findsOneWidget);

      // Clean up
      await userStateController.close();
    });

    testWidgets('displays user list when search is successful', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final userStateController = StreamController<UserListState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserListInitial());

      final mockUsers = [
        User(
          id: '1',
          login: 'user-1',
          email: 'admin@example.com',
          firstName: 'Admin',
          lastName: 'Tester',
          activated: true,
          langKey: 'en',
          createdBy: 'system',
          createdDate: kTestInstant,
          lastModifiedBy: "system",
          lastModifiedDate: kTestInstant,
          authorities: const ['ROLE_ADMIN'],
        ),
      ];

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Simulate successful search
      userStateController.add(UserListLoaded(users: mockUsers));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('admin@example.com'), findsOneWidget);
      expect(find.text('Tester'), findsOneWidget);
      expect(find.text('Active'), findsNWidgets(2)); // header + data badge

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles search button tap', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final userStateController = StreamController<UserListState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserListInitial());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Fill search form
      await tester.enterText(find.byType(FormBuilderTextField).first, '0');
      await tester.enterText(find.byType(FormBuilderTextField).at(1), '100');

      // Tap search button
      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      verify(() => mockUserBloc.add(any(that: isA<UserListSearch>()))).called(1);

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles create button tap', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final userStateController = StreamController<UserListState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserListInitial());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.byKey(const Key('listUserCreateButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      // Verify navigation occurred (router should handle the actual navigation)
      expect(find.text('create-route'), findsOneWidget);

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles screen size responsiveness', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserListState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserListInitial());

      // Test large screen
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT & ASSERT for large screen
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Test small screen - shows mobile card-based list (no SingleChildScrollView)
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);

      // Clean up
      await userStateController.close();
    });
  });

  group('UserListScreen states on a phone', () {
    Future<void> pumpPhone(WidgetTester tester, UserListState initialState, [Stream<UserListState>? states]) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      whenListen(mockUserBloc, states ?? const Stream<UserListState>.empty(), initialState: initialState);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
    }

    testWidgets('shows the empty placeholder before the first search', (tester) async {
      await pumpPhone(tester, const UserListInitial());

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a progress indicator while a request runs', (tester) async {
      await pumpPhone(tester, const UserListLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsNothing);
    });

    testWidgets('refreshes the list after a delete without showing an error', (tester) async {
      await pumpPhone(tester, const UserListInitial(), Stream.value(const UserListDeleteSuccess()));
      await tester.pump();

      verify(() => mockUserBloc.add(any(that: isA<UserListSearch>()))).called(1);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.text(S.current.error_generic), findsNothing);
    });

    testWidgets('shows the error instead of the empty placeholder when a request fails', (tester) async {
      await pumpPhone(tester, const UserListFailure(error: 'User service unavailable'));

      expect(find.text(S.current.error_generic), findsOneWidget);
      expect(find.text('User service unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsNothing);
    });
  });

  group('UserListScreen in the app', () {
    late MockIUserRepository userRepository;

    setUp(() async {
      userRepository = MockIUserRepository();
      TestEnv.authenticate();
      await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_ADMIN']);
    });

    void stubSearch(Result<List<UserEntity>> result) {
      when(
        () => userRepository.list(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => result);
    }

    // The authenticated shell keeps animating (dashboard skeletons), so pumpAndSettle would time out there.
    Future<void> pumpShell(WidgetTester tester) async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // What an admin does: open the user list and press List with the default filters.
    Future<void> searchUsers(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(App(language: 'en', dependencies: _UserRepositoryDependencies(userRepository)));
      await pumpShell(tester);
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(ApplicationRoutesConstants.userList);
      await pumpShell(tester);

      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      await pumpShell(tester);
    }

    testWidgets('shows the error instead of an empty list when the search fails', (tester) async {
      stubSearch(const Failure(NetworkError('User service unavailable')));

      await searchUsers(tester);

      expect(find.text(S.current.error_generic), findsOneWidget);
      expect(find.text('User service unavailable'), findsOneWidget);
      expect(find.text('0 row(s) listed.'), findsNothing);
    });

    testWidgets('loads the users again from the error state', (tester) async {
      stubSearch(const Failure(NetworkError('User service unavailable')));
      await searchUsers(tester);

      stubSearch(
        const Success([
          UserEntity(
            id: '7',
            login: 'grace.hopper',
            firstName: 'Grace',
            lastName: 'Hopper',
            email: 'grace.hopper@example.com',
            activated: true,
            authorities: ['ROLE_USER'],
          ),
        ]),
      );
      await tester.tap(find.text(S.current.refresh));
      await pumpShell(tester);

      expect(find.text('grace.hopper@example.com'), findsOneWidget);
      expect(find.text(S.current.error_generic), findsNothing);
    });
  });
}

/// Mock-mode app dependencies whose user list is served by [userRepository].
class _UserRepositoryDependencies extends AppDependencies {
  const _UserRepositoryDependencies(this.userRepository);

  final IUserRepository userRepository;

  @override
  IUserRepository createUserRepository(ApiClient apiClient) => userRepository;
}
