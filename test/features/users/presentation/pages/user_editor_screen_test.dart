@Tags(['widget'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/editor_form_mode.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockAuthorityBloc mockAuthorityBloc;
  late MockUserEditorBloc mockUserBloc;

  setUp(() async {
    mockUserBloc = MockUserEditorBloc();
    mockAuthorityBloc = MockAuthorityBloc();

    when(() => mockAuthorityBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      ]),
    );
    when(
      () => mockAuthorityBloc.state,
    ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
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
        BlocProvider<UserEditorBloc>.value(value: mockUserBloc),
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
      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorActivatedFieldKey')), findsOneWidget);
      expect(find.byType(AuthoritiesDropdown), findsOneWidget);
    });

    testWidgets('Edit Mode - Should load and display user data', (tester) async {
      // ARRANGE
      const userId = 'test-user-1';
      const mockUser = User(
        id: userId,
        login: 'testuser',
        firstName: 'Test',
        lastName: 'Tester',
        email: 'test@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );

      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(
        mockUserBloc,
        Stream.fromIterable([const UserEditorLoading(), UserEditorLoaded(data: mockUser)]),
        initialState: const UserEditorInitial(),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.edit, id: userId));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Tester'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      verify(() => mockUserBloc.add(any(that: isA<UserEditorFetch>()))).called(1);
    });

    testWidgets('View Mode - Should display read-only form', (tester) async {
      // ARRANGE
      const userId = 'test-user-1';
      const mockUser = User(
        id: userId,
        login: 'testuser',
        firstName: 'Test',
        lastName: 'Tester',
        email: 'test@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );

      when(() => mockUserBloc.state).thenReturn(UserEditorLoaded(data: mockUser));
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: UserEditorLoaded(data: mockUser));

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.view, id: userId));
      await tester.pumpAndSettle();

      // ASSERT
      final loginField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('userEditorLoginFieldKey')), matching: find.byType(TextField)),
      );
      expect(loginField.enabled, false);

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Tester'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Create Mode - Should validate form before submit', (tester) async {
      // ARRANGE
      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
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

      verifyNever(() => mockUserBloc.add(any(that: isA<UserEditorSubmit>())));
    });

    testWidgets('Create Mode - Should submit valid form', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ARRANGE
      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // Fill all required text fields.
      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'newuser');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'New');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'User');
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'new@example.com');
      // Allow onChanged callbacks to propagate before selecting the authority.
      await tester.pumpAndSettle();

      // The AuthoritiesDropdown (isRequired: true) must have a non-empty value or
      // saveAndValidate() returns false and UserEditorSubmit is never dispatched.
      // Tap the dropdown to open the popup menu, then select 'ROLE_USER'.
      await tester.ensureVisible(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ROLE_USER').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT — UserEditorSubmit must be dispatched exactly once for a fully valid form.
      verify(() => mockUserBloc.add(any(that: isA<UserEditorSubmit>()))).called(1);
    });

    testWidgets('Should handle cancel button tap', (tester) async {
      // ARRANGE
      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      when(
        () => mockAuthorityBloc.state,
      ).thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(
        () => mockAuthorityBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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
    });
  });
}
