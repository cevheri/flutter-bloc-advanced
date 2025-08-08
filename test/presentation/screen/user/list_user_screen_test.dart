import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/user_routes.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'list_user_screen_test.mocks.dart';

@GenerateMocks([UserBloc, UserRepository, AuthorityBloc, AuthorityRepository])
void main() {
  late MockUserRepository mockUserRepository;
  late MockAuthorityBloc mockAuthorityBloc;
  late MockAuthorityRepository mockAuthorityRepository;
  late MockUserBloc mockUserBloc;
  late TestUtils testUtils;

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    mockUserRepository = MockUserRepository();
    mockUserBloc = MockUserBloc();
    mockAuthorityBloc = MockAuthorityBloc();
    mockAuthorityRepository = MockAuthorityRepository();

    // Set up default AuthorityBloc behavior
    when(mockAuthorityBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      ]),
    );
    when(mockAuthorityBloc.state).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
    UserRoutes.dispose();
  });

  Widget buildTestableWidget() {
    UserRoutes.init(
      userBloc: mockUserBloc,
      userRepository: mockUserRepository,
      authorityBloc: mockAuthorityBloc,
      authorityRepository: mockAuthorityRepository,
    );

    final router = GoRouter(initialLocation: '/user', routes: UserRoutes.routes);

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>.value(value: mockUserBloc),
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

  group('ListUserScreen Tests', () {
    testWidgets('renders ListUserScreen correctly', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byType(FormBuilderTextField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsNWidgets(2));
      expect(find.text(S.current.list), findsOneWidget);
      expect(find.text(S.current.list_user), findsOneWidget);

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
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      final mockUsers = [
        User(
          id: '1',
          login: 'user-1',
          email: 'admin@example.com',
          firstName: 'Admin',
          lastName: 'User',
          activated: true,
          langKey: 'en',
          createdBy: 'system',
          createdDate: DateTime.now(),
          lastModifiedBy: "system",
          lastModifiedDate: DateTime.now(),
          authorities: const ['ROLE_ADMIN'],
        ),
      ];

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Simulate successful search
      userStateController.add(UserState(status: UserStatus.searchSuccess, userList: mockUsers));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('admin@example.com'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('active'), findsOneWidget);

      //expect(find.byWidgetPredicate((widget) => widget is Text && widget.data == 'Admin' && widget.textAlign == TextAlign.left), findsOneWidget);

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles search button tap', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

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
      verify(mockUserBloc.add(any)).called(greaterThan(0));

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles create button tap', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.byKey(const Key('listUserCreateButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      // Verify navigation occurred (router should handle the actual navigation)
      expect(find.byType(ListUserScreen), findsNothing);

      // Clean up
      await userStateController.close();
    });

    testWidgets('handles screen size responsiveness', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // Test large screen
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // ACT & ASSERT for large screen
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text(S.current.screen_size_error), findsNothing);

      // Test small screen
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(find.text(S.current.screen_size_error), findsOneWidget);

      // Clean up
      await userStateController.close();
      addTearDown(tester.view.reset);
    });
  });
}
