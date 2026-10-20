@Tags(['widget'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart' show Interceptor, RequestInterceptorHandler, RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_list_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_responsive_list_view.dart';
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

    testWidgets('shows the role filter placeholder once while no role is chosen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      whenListen(mockUserBloc, const Stream<UserListState>.empty(), initialState: const UserListInitial());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Role filter'), findsOneWidget);
    });

    // The table has no way to hide a column, so a Columns button could only do nothing.
    testWidgets('offers no Columns button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      whenListen(mockUserBloc, const Stream<UserListState>.empty(), initialState: const UserListInitial());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Columns'), findsNothing);
      expect(find.byIcon(Icons.view_column_outlined), findsNothing);
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
      await pumpPhone(tester, const UserListLoadFailure(errorCode: AppErrorCode.generic));

      expect(find.text(S.current.user_list_load_failed), findsOneWidget);
      expect(find.text(S.current.error_generic), findsOneWidget);
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

    Future<void> openUserList(WidgetTester tester, {String language = 'en', Size size = const Size(1600, 1600)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(App(language: language, dependencies: _UserRepositoryDependencies(userRepository)));
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(ApplicationRoutesConstants.userList);
      await tester.pumpAndSettle();
    }

    // What an admin does: open the user list and press List with the default filters.
    Future<void> searchUsers(WidgetTester tester, {String language = 'en'}) async {
      await openUserList(tester, language: language);

      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      await tester.pumpAndSettle();
    }

    final nameField = find.byWidgetPredicate((widget) => widget is FormBuilderTextField && widget.name == 'name');

    const grace = UserEntity(
      id: '7',
      login: 'grace.hopper',
      firstName: 'Grace',
      lastName: 'Hopper',
      email: 'grace.hopper@example.com',
      activated: true,
      authorities: ['ROLE_USER'],
    );

    testWidgets('lists the users whose name matches when no role is selected', (tester) async {
      when(() => userRepository.listByName(0, 100, 'grace')).thenAnswer((_) async => const Success([grace]));
      await openUserList(tester);

      await tester.enterText(nameField, 'grace');
      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      await tester.pumpAndSettle();

      expect(find.text('grace.hopper@example.com'), findsOneWidget);
    });

    testWidgets('lists the users whose name matches on a phone, which has no role filter', (tester) async {
      when(() => userRepository.listByName(0, 100, 'grace')).thenAnswer((_) async => const Success([grace]));
      await openUserList(tester, size: const Size(400, 800));

      await tester.enterText(nameField, 'grace');
      await tester.tap(find.ancestor(of: find.text(S.current.list), matching: find.byType(OutlinedButton)));
      await tester.pumpAndSettle();

      expect(find.text('grace.hopper@example.com'), findsOneWidget);
    });

    testWidgets('shows the error instead of loading forever when the search throws', (tester) async {
      when(
        () => userRepository.list(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(StateError('Unexpected response'));

      await searchUsers(tester);

      expect(find.text(S.current.user_list_load_failed), findsOneWidget);
      expect(find.text(S.current.error_generic), findsOneWidget);
    });

    testWidgets('shows the error instead of an empty list when the search fails', (tester) async {
      stubSearch(const Failure(NetworkError('User service unavailable')));

      await searchUsers(tester);

      expect(find.text(S.current.user_list_load_failed), findsOneWidget);
      expect(find.text(S.current.error_generic), findsOneWidget);
      expect(find.text('User service unavailable'), findsNothing);
      expect(find.text('0 row(s) listed.'), findsNothing);
    });

    testWidgets('shows why a delete was refused in the app language', (tester) async {
      // The list deletes a user by login, and DeleteUserUseCase refuses the admin's login.
      stubSearch(
        const Success([
          UserEntity(
            id: '1',
            login: 'admin',
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@example.com',
            activated: true,
            authorities: ['ROLE_ADMIN'],
          ),
        ]),
      );
      await searchUsers(tester, language: 'tr');

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet'));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcı silinemedi'), findsOneWidget);
      expect(find.text('Yönetici kullanıcı silinemez'), findsOneWidget);
      expect(find.text('Admin user cannot be deleted'), findsNothing);
    });

    testWidgets('keeps the users listed and shows why when the delete fails', (tester) async {
      stubSearch(const Success([grace]));
      when(() => userRepository.delete('grace.hopper'))
          .thenAnswer((_) async => const Failure(NetworkError('User service unavailable')));
      await searchUsers(tester);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.yes));
      await tester.pumpAndSettle();

      verify(() => userRepository.delete('grace.hopper')).called(1);
      final table = find.byType(AppDataTable<UserEntity>);
      expect(find.descendant(of: table, matching: find.text('grace.hopper@example.com')), findsOneWidget);
      final snackBar = find.byType(SnackBar);
      expect(find.descendant(of: snackBar, matching: find.text(S.current.user_delete_failed)), findsOneWidget);
      expect(find.descendant(of: snackBar, matching: find.text(S.current.error_generic)), findsOneWidget);
      expect(find.text('User service unavailable'), findsNothing);
    });

    testWidgets('shows that the users are loading instead of an empty table on a desktop', (tester) async {
      final response = Completer<Result<List<UserEntity>>>();
      when(
        () => userRepository.list(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => response.future);

      await openUserList(tester);
      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      // The skeleton rows shimmer until the request completes, so pump a few frames instead of settling.
      await tester.pump(const Duration(milliseconds: 500));

      final userList = find.byType(AppResponsiveListView<UserEntity>);
      expect(find.descendant(of: userList, matching: find.byType(AppSkeleton)), findsWidgets);
      expect(find.text('0 row(s) listed.'), findsNothing);

      response.complete(const Success([grace]));
      await tester.pumpAndSettle();

      expect(find.text('grace.hopper@example.com'), findsOneWidget);
      expect(find.descendant(of: userList, matching: find.byType(AppSkeleton)), findsNothing);
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
      await tester.pumpAndSettle();

      expect(find.text('grace.hopper@example.com'), findsOneWidget);
      expect(find.text(S.current.error_generic), findsNothing);
    });
  });

  group('UserListScreen against the mock API', () {
    late List<RequestOptions> requests;

    setUp(() async {
      requests = [];
      TestEnv.authenticate();
      await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_ADMIN']);
    });

    // What an admin does: list the users, press delete on the row with [email] and confirm.
    Future<void> deleteUser(WidgetTester tester, String email) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(App(language: 'en', dependencies: _RecordingDependencies(requests)));
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(ApplicationRoutesConstants.userList);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('listUserSubmitButtonKey')));
      await tester.pumpAndSettle();

      final emailCell = find.descendant(of: find.byType(AppDataTable<UserEntity>), matching: find.text(email));
      final row = find.ancestor(of: emailCell, matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.delete)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.yes));
      await tester.pumpAndSettle();
    }

    List<String> deletedPaths() =>
        requests.where((request) => request.method == 'DELETE').map((request) => request.path).toList();

    // Guards that the row deletes by login, the identifier the admin guard checks.
    testWidgets('deletes a user by login, which the API takes', (tester) async {
      await deleteUser(tester, 'mock_account-2@test.com');

      expect(deletedPaths(), ['/admin/users/new_user-2']);
    });

    testWidgets('refuses to delete the admin without sending the delete', (tester) async {
      await deleteUser(tester, 'admin@sample.tech');

      expect(find.text(S.current.error_user_cannot_delete_admin), findsOneWidget);
      expect(deletedPaths(), isEmpty);
    });

    testWidgets('keeps the users listed and shows the refusal in a snack bar', (tester) async {
      await deleteUser(tester, 'admin@sample.tech');

      final table = find.byType(AppDataTable<UserEntity>);
      expect(find.descendant(of: table, matching: find.text('admin@sample.tech')), findsOneWidget);
      expect(find.descendant(of: table, matching: find.text('mock_account-2@test.com')), findsOneWidget);
      final snackBar = find.byType(SnackBar);
      expect(find.descendant(of: snackBar, matching: find.text(S.current.user_delete_failed)), findsOneWidget);
      expect(
        find.descendant(of: snackBar, matching: find.text(S.current.error_user_cannot_delete_admin)),
        findsOneWidget,
      );
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

/// Test-mode app dependencies whose API client records each request the mock API answers in [requests].
class _RecordingDependencies extends AppDependencies {
  const _RecordingDependencies(this.requests) : super(appConfig: const AppConfig.test());

  final List<RequestOptions> requests;

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) {
    final apiClient = super.createApiClient(secureStorage, onSessionExpired: onSessionExpired);
    // MockInterceptor comes last and answers in place of the server, so the recorder goes right before it.
    final interceptors = apiClient.instance.interceptors;
    interceptors.insert(interceptors.length - 1, _RequestRecorder(requests));
    return apiClient;
  }
}

class _RequestRecorder extends Interceptor {
  _RequestRecorder(this.requests);

  final List<RequestOptions> requests;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.next(options);
  }
}
