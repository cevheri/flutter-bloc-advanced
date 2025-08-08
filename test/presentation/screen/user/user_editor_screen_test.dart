import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/authorities_lov_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/user_routes.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'user_editor_screen_test.mocks.dart';

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

  Widget buildTestableWidget({required EditorFormMode mode, String? id}) {
    // Initialize UserRoutes with mock objects
    UserRoutes.init(
      userBloc: mockUserBloc,
      userRepository: mockUserRepository,
      authorityBloc: mockAuthorityBloc,
      authorityRepository: mockAuthorityRepository,
    );

    final router = GoRouter(
      initialLocation: id != null ? '/user/$id/${mode.name}' : '/user/new',
      routes: UserRoutes.routes,
    );

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

  group('UserEditorScreen Tests', () {
    testWidgets('Create Mode - Should render empty form', (tester) async {
      // ARRANGE
      // Set up UserBloc
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // Set up AuthorityBloc
      when(
        mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // Mock UserBloc event handling
      when(mockUserBloc.add(any)).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));

      // Wait for initial build
      await tester.pump();

      // Wait for async operations
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorActivatedFieldKey')), findsOneWidget);
      expect(find.byType(AuthoritiesDropdown), findsOneWidget);

      // Verify bloc interactions
      verify(mockUserBloc.add(any)).called(1);

      // Clean up
      await userStateController.close();
    });

    testWidgets('Edit Mode - Should load and display user data', (tester) async {
      // ARRANGE
      const userId = 'test-user-1';
      const mockUser = User(
        id: userId,
        login: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );

      // Mock repository call first
      when(mockUserRepository.retrieve(userId)).thenAnswer((_) async => mockUser);

      // Set up UserBloc state and event handling
      when(mockUserBloc.state).thenReturn(const UserState());

      // Create a StreamController for UserBloc states
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);

      // Mock UserBloc event handling with proper event type
      when(mockUserBloc.add(any)).thenAnswer((invocation) async {
        if (invocation.positionalArguments[0] is UserFetchEvent) {
          // Emit loading state first
          userStateController.add(const UserState(status: UserStatus.loading));
          // Then emit success state with data
          await Future.delayed(const Duration(milliseconds: 100));
          userStateController.add(const UserState(status: UserStatus.fetchSuccess, data: mockUser));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.edit, id: userId));

      // Wait for initial build
      await tester.pump();

      // Wait for async operations and state changes
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ASSERT
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Verify repository and bloc interactions
      verify(mockUserBloc.add(any)).called(1);

      // Clean up
      await userStateController.close();
    });

    testWidgets('View Mode - Should display read-only form', (tester) async {
      // ARRANGE
      const userId = 'test-user-1';
      const mockUser = User(
        id: userId,
        login: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );

      // Set up UserBloc
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState(data: mockUser));

      // Set up AuthorityBloc
      when(
        mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // Mock UserBloc event handling
      when(mockUserBloc.add(any)).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserFetchEvent) {
          userStateController.add(const UserState(data: mockUser));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.view, id: userId));

      // Wait for initial build
      await tester.pump();

      // Wait for async operations
      await tester.pumpAndSettle();

      // ASSERT
      final loginField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('userEditorLoginFieldKey')), matching: find.byType(TextField)),
      );
      expect(loginField.enabled, false);

      // Verify data is displayed
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Clean up
      await userStateController.close();
    });

    testWidgets('Create Mode - Should validate form before submit', (tester) async {
      // ARRANGE
      // Set up UserBloc
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // Set up AuthorityBloc
      when(
        mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // Mock UserBloc event handling
      when(mockUserBloc.add(any)).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pump();
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text(S.current.required_field), findsWidgets);

      // Alternatif olarak, belirli form alanlarının validasyon durumunu kontrol et
      final loginField = tester.widget<FormBuilderTextField>(find.byKey(const Key('userEditorLoginFieldKey')));
      expect(loginField.validator, isNotNull);

      // Verify bloc interactions
      verify(mockUserBloc.add(any)).called(1);

      // Clean up
      await userStateController.close();
    });

    testWidgets('Create Mode - Should submit valid form', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // Set up AuthorityBloc
      when(
        mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // const newUser = User(
      //   login: 'newuser',
      //   firstName: 'New',
      //   lastName: 'User',
      //   email: 'new@example.com',
      //   activated: true,
      //   authorities: ['ROLE_USER'],
      // );

      // Mock UserBloc event handling
      when(mockUserBloc.add(any)).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        } else if (invocation.positionalArguments[0] is UserSubmitEvent) {
          userStateController.add(const UserState(status: UserStatus.success));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'newuser');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'New');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'User');
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'new@example.com');

      // Submit form
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      verify(mockUserBloc.add(any)).called(greaterThan(0));

      // Clean up
      await userStateController.close();
    });

    testWidgets('Should handle cancel button tap', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // Set up AuthorityBloc
      when(
        mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // Mock UserBloc event handling
      when(mockUserBloc.add(any)).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // Fill some data to make form dirty
      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'testuser');

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ASSERT
      // Dialog should appear
      expect(find.text(S.current.warning), findsOneWidget);
      expect(find.text(S.current.unsaved_changes), findsOneWidget);

      // Tap "No" to stay on the form
      await tester.tap(find.text(S.current.no));
      await tester.pumpAndSettle();

      // Form should still be visible
      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);

      // Clean up
      await userStateController.close();
    });
  });
}
