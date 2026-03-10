import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/editor_form_mode.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/navigation/users_routes.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../test_utils.dart';

void main() {
  late MockUserRepository mockUserRepository;
  late MockAuthorityBloc mockAuthorityBloc;
  late MockAuthorityRepository mockAuthorityRepository;
  late MockUserBloc mockUserBloc;
  late TestUtils testUtils;

  setUpAll(() {
    registerAllFallbackValues();
  });

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    mockUserRepository = MockUserRepository();
    mockUserBloc = MockUserBloc();
    mockAuthorityBloc = MockAuthorityBloc();
    mockAuthorityRepository = MockAuthorityRepository();

    when(() => mockAuthorityBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      ]),
    );
    when(
      () => mockAuthorityBloc.state,
    ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  Widget buildTestableWidget({required EditorFormMode mode, String? id}) {
    final router = GoRouter(
      initialLocation: id != null ? '/user/$id/${mode.name}' : '/user/new',
      routes: [
        GoRoute(
          path: '/user/new',
          builder: (context, state) => const Scaffold(body: UserEditorPage(mode: EditorFormMode.create)),
        ),
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
      ],
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
      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserState());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pump();
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorActivatedFieldKey')), findsOneWidget);
      expect(find.byType(AuthoritiesDropdown), findsOneWidget);

      verify(() => mockUserBloc.add(any())).called(1);

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

      when(() => mockUserRepository.retrieve(userId)).thenAnswer((_) async => mockUser);
      when(() => mockUserBloc.state).thenReturn(const UserState());

      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) async {
        if (invocation.positionalArguments[0] is UserFetchEvent) {
          userStateController.add(const UserState(status: UserStatus.loading));
          await Future.delayed(const Duration(milliseconds: 100));
          userStateController.add(const UserState(status: UserStatus.fetchSuccess, data: mockUser));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.edit, id: userId));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ASSERT
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      verify(() => mockUserBloc.add(any())).called(1);

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

      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserState(data: mockUser));

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserFetchEvent) {
          userStateController.add(const UserState(data: mockUser));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.view, id: userId));
      await tester.pump();
      await tester.pumpAndSettle();

      // ASSERT
      final loginField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('userEditorLoginFieldKey')), matching: find.byType(TextField)),
      );
      expect(loginField.enabled, false);

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      await userStateController.close();
    });

    testWidgets('Create Mode - Should validate form before submit', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserState());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('userEditorLoginFieldKey')));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text(S.current.required_field), findsWidgets);

      final loginField = tester.widget<FormBuilderTextField>(find.byKey(const Key('userEditorLoginFieldKey')));
      expect(loginField.validator, isNotNull);

      verify(() => mockUserBloc.add(any())).called(1);

      await userStateController.close();
    });

    testWidgets('Create Mode - Should submit valid form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserState());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        } else if (invocation.positionalArguments[0] is UserSubmitEvent) {
          userStateController.add(const UserState(status: UserStatus.saveSuccess));
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'newuser');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'New');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'User');
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'new@example.com');

      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      verify(() => mockUserBloc.add(any())).called(greaterThan(0));

      await userStateController.close();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Should handle cancel button tap', (tester) async {
      // ARRANGE
      final userStateController = StreamController<UserState>.broadcast();
      when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(() => mockUserBloc.state).thenReturn(const UserState());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      when(() => mockUserBloc.add(any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0] is UserEditorInit) {
          userStateController.add(const UserState());
        }
      });

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'testuser');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text(S.current.warning), findsOneWidget);
      expect(find.text(S.current.unsaved_changes), findsOneWidget);

      await tester.tap(find.text(S.current.no));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);

      await userStateController.close();
    });
  });
}
