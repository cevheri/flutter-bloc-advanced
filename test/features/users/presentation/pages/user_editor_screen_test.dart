@Tags(['widget'])
library;

import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart' show Interceptor, RequestInterceptorHandler, RequestOptions, Response;
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
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/editor_form_mode.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';
import '../../../../support/unsaved_changes_host.dart';

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
    when(() => mockAuthorityBloc.state)
        .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
  });

  Widget buildTestableWidget({required EditorFormMode mode, String? id, Locale locale = const Locale('en')}) {
    final router = GoRouter(
      initialLocation: id != null ? '/user/$id/${mode.name}' : '/user/new',
      routes: [
        GoRoute(
          path: '/user/new',
          onExit: confirmLeavingUnsavedChanges,
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
      child: withUnsavedChangesRegistry(
        MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      ),
    );
  }

  group('UserEditorScreen - Turkish', () {
    testWidgets('Create Mode - shows the form texts and its actions in Turkish', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create, locale: const Locale('tr')));
      await tester.pumpAndSettle();

      for (final text in [
        'Yeni bir kullanıcı oluşturmak için bilgileri doldurun.',
        'Kullanıcı Bilgileri',
        'Kimlik, iletişim ve erişim ayarlarını yönetin.',
        'Kimlik',
        'Temel hesap kimlik bilgileri.',
        'İletişim',
        'Birincil iletişim bilgileri.',
        'Erişim',
        'Hesap durumu ve rol yetkileri.',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.widgetWithText(OutlinedButton, 'İptal'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Kaydet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (mode, subtitle) in const [
      (EditorFormMode.edit, 'Kullanıcı bilgilerini aşağıda güncelleyin.'),
      (EditorFormMode.view, 'Kullanıcı ayrıntılarını görüntüleyin.'),
    ]) {
      testWidgets('${mode.name} mode - shows its subtitle in Turkish', (tester) async {
        const user = User(id: 'test-user-1', login: 'testuser', firstName: 'Test', lastName: 'Tester');
        when(() => mockUserBloc.state).thenReturn(UserEditorLoaded(data: user));
        whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: UserEditorLoaded(data: user));

        await tester.pumpWidget(buildTestableWidget(mode: mode, id: 'test-user-1', locale: const Locale('tr')));
        await tester.pumpAndSettle();

        expect(find.text(subtitle), findsOneWidget);
      });
    }
  });

  group('UserEditorScreen Tests', () {
    testWidgets('Create Mode - Should render empty form', (tester) async {
      // ARRANGE
      when(() => mockUserBloc.state).thenReturn(const UserEditorInitial());
      whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

      when(() => mockAuthorityBloc.state)
          .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(() => mockAuthorityBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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

    for (final width in [320.0, 412.0]) {
      testWidgets('Create Mode - fits the title and subtitle on a ${width.toInt()} px wide phone', (tester) async {
        tester.view.physicalSize = Size(width, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        whenListen(mockUserBloc, const Stream<UserEditorState>.empty(), initialState: const UserEditorInitial());

        await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(S.current.create_user), findsWidgets);
      });
    }

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

      when(() => mockAuthorityBloc.state)
          .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(() => mockAuthorityBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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

      when(() => mockAuthorityBloc.state)
          .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(() => mockAuthorityBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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

      when(() => mockAuthorityBloc.state)
          .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(() => mockAuthorityBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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
      // Tap the dropdown to open the popup menu, then select the user role, which it names Guest.
      await tester.ensureVisible(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guest').last);
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

      when(() => mockAuthorityBloc.state)
          .thenReturn(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']));
      when(() => mockAuthorityBloc.stream)
          .thenAnswer((_) => Stream.value(const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER'])));

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

  group('UserEditorScreen in the app', () {
    late MockIUserRepository userRepository;

    const grace = UserEntity(
      id: '7',
      login: 'grace.hopper',
      firstName: 'Grace',
      lastName: 'Hopper',
      email: 'grace.hopper@example.com',
      activated: true,
      authorities: ['ROLE_USER'],
    );

    setUp(() async {
      userRepository = MockIUserRepository();
      TestEnv.authenticate();
      await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_ADMIN']);
    });

    // What an admin does: open a user from the list, here by going to its address.
    Future<void> openEditor(WidgetTester tester, String location) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(App(language: 'en', dependencies: _UserRepositoryDependencies(userRepository)));
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    for (final mode in ['edit', 'view']) {
      testWidgets('shows an error with a retry when the user to $mode cannot be loaded', (tester) async {
        when(() => userRepository.retrieve('grace.hopper'))
            .thenAnswer((_) async => const Failure(NetworkError('User service unavailable')));

        await openEditor(tester, '/user/grace.hopper/$mode');
        expect(find.byType(SnackBar), findsNothing);
        await tester.pumpAndSettle();

        expect(find.text(S.current.user_load_failed), findsOneWidget);
        expect(find.text(S.current.error_generic), findsOneWidget);
        expect(find.text('User service unavailable'), findsNothing);
        expect(find.text('No data'), findsNothing);
        expect(find.byKey(const Key('userEditorAppBarBackButtonKey')), findsOneWidget);

        when(() => userRepository.retrieve('grace.hopper')).thenAnswer((_) async => const Success(grace));
        await tester.tap(find.text(S.current.refresh));
        await tester.pumpAndSettle();

        expect(find.text('grace.hopper@example.com'), findsOneWidget);
        expect(find.text(S.current.user_load_failed), findsNothing);
        // The reloaded page starts more requests; let the mock API's 500 ms delay pass so none is left pending.
        await tester.pump(const Duration(milliseconds: 600));
      });
    }

    testWidgets('keeps the form and the edits when saving the user fails', (tester) async {
      when(() => userRepository.retrieve('grace.hopper')).thenAnswer((_) async => const Success(grace));
      when(() => userRepository.update(any()))
          .thenAnswer((_) async => const Failure(NetworkError('User service unavailable')));
      await openEditor(tester, '/user/grace.hopper/edit');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Amazing Grace');
      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('No data'), findsNothing);

      // Saving again still updates the same user instead of creating a new one.
      when(() => userRepository.update(any())).thenAnswer((_) async => const Success(grace));
      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      verify(
        () => userRepository.update(
          any(
            that: isA<UserEntity>()
                .having((user) => user.id, 'id', '7')
                .having((user) => user.firstName, 'firstName', 'Amazing Grace'),
          ),
        ),
      ).called(2);
      verifyNever(() => userRepository.create(any()));
    });

    testWidgets('keeps the language of a user saved without changes', (tester) async {
      const ayse = UserEntity(
        id: '9',
        login: 'ayse.yilmaz',
        firstName: 'Ayşe',
        lastName: 'Yılmaz',
        email: 'ayse.yilmaz@example.com',
        activated: true,
        langKey: 'tr',
        authorities: ['ROLE_USER'],
      );
      when(() => userRepository.retrieve('ayse.yilmaz')).thenAnswer((_) async => const Success(ayse));
      when(() => userRepository.update(any())).thenAnswer((_) async => const Success(ayse));
      await openEditor(tester, '/user/ayse.yilmaz/edit');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      verify(() => userRepository.update(any(that: isA<UserEntity>().having((user) => user.langKey, 'langKey', 'tr'))))
          .called(1);
    });
  });

  group('UserEditorScreen against the mock API', () {
    late List<RequestOptions> requests;

    setUp(() async {
      requests = [];
      TestEnv.authenticate();
      await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_ADMIN']);
    });

    // What an admin does: open a user from the list (here by going to its address) or the new user form.
    Future<void> open(
      WidgetTester tester,
      String location, {
      Map<String, Object> answers = const {},
      String language = 'en',
    }) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        App(
          language: language,
          dependencies: _RecordingDependencies(requests, answers: answers),
        ),
      );
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(location);
      await tester.pumpAndSettle();
    }

    Future<void> chooseRole(WidgetTester tester, String role) async {
      await tester.ensureVisible(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.tap(find.byKey(const Key('userEditorAuthoritiesFieldKey')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(role).last);
      await tester.pumpAndSettle();
    }

    // Saves and returns the body of the request sent with [method].
    Future<Map<String, dynamic>> save(WidgetTester tester, String method) async {
      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();
      return requests.singleWhere((request) => request.method == method).data as Map<String, dynamic>;
    }

    testWidgets('saving the admin without changes keeps its language and both roles', (tester) async {
      await open(tester, '/user/admin/edit');

      final update = await save(tester, 'PUT');

      expect(update, containsPair('login', 'admin'));
      expect(update, containsPair('langKey', 'en'));
      expect(update, containsPair('authorities', ['ROLE_ADMIN', 'ROLE_USER']));
    });

    // Guards that picking a role other than the one shown replaces all of the user's roles with it.
    testWidgets('saving the admin with another role gives it that role', (tester) async {
      await open(tester, '/user/admin/edit');
      await chooseRole(tester, 'Guest');

      final update = await save(tester, 'PUT');

      expect(update, containsPair('authorities', ['ROLE_USER']));
    });

    // A Spring backend sends the roles from a HashSet, which lists ROLE_USER before ROLE_ADMIN.
    const mixedRoles = {
      'id': 'user-9',
      'login': 'mixed.roles',
      'firstName': 'Mixed',
      'lastName': 'Roles',
      'email': 'mixed.roles@example.com',
      'activated': true,
      'langKey': 'en',
      'authorities': ['ROLE_USER', 'ROLE_ADMIN'],
    };

    testWidgets('shows the admin role of a user whose roles arrive with ROLE_USER first', (tester) async {
      await open(tester, '/user/mixed.roles/edit', answers: {'/admin/users/mixed.roles': mixedRoles});

      final field = find.byKey(const Key('userEditorAuthoritiesFieldKey'));
      expect(find.descendant(of: field, matching: find.text('Admin')), findsOneWidget);
      expect(find.descendant(of: field, matching: find.text('Guest')), findsNothing);
    });

    // The role field and its menu showed the role codes ROLE_ADMIN and ROLE_USER in every language.
    testWidgets('names the roles the way the user list does, in Turkish', (tester) async {
      await open(tester, '/user/admin/edit', language: 'tr');

      final field = find.byKey(const Key('userEditorAuthoritiesFieldKey'));
      expect(find.descendant(of: field, matching: find.text('Admin')), findsOneWidget);

      await tester.tap(field);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PopupMenuItem<String?>, 'Kullanıcı'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String?>, 'Admin'), findsOneWidget);
      expect(find.textContaining('ROLE_'), findsNothing);
    });

    testWidgets('picking ROLE_USER for a user whose roles arrive with ROLE_USER first saves that role', (tester) async {
      await open(tester, '/user/mixed.roles/edit', answers: {'/admin/users/mixed.roles': mixedRoles});
      await chooseRole(tester, 'Guest');

      final update = await save(tester, 'PUT');

      expect(update, containsPair('login', 'mixed.roles'));
      expect(update, containsPair('authorities', ['ROLE_USER']));
    });

    // Guards that a new user, with no fetched user to start from, is saved in English with the chosen role.
    testWidgets('creating a user saves it in English with the chosen role', (tester) async {
      await open(tester, ApplicationRoutesConstants.userNew);
      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'ada.lovelace');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Ada');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Lovelace');
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'ada.lovelace@example.com');
      await chooseRole(tester, 'Guest');

      final created = await save(tester, 'POST');

      expect(created, isNot(contains('id')));
      expect(created, containsPair('login', 'ada.lovelace'));
      expect(created, containsPair('langKey', 'en'));
      expect(created, containsPair('authorities', ['ROLE_USER']));
    });
  });
}

/// Mock-mode app dependencies whose users are served by [userRepository].
class _UserRepositoryDependencies extends AppDependencies {
  const _UserRepositoryDependencies(this.userRepository);

  final IUserRepository userRepository;

  @override
  IUserRepository createUserRepository(ApiClient apiClient) => userRepository;
}

/// Test-mode app dependencies whose API client records each request the mock API answers in [requests]. A GET of a
/// path in [answers] gets its body in place of the mock API's.
class _RecordingDependencies extends AppDependencies {
  const _RecordingDependencies(this.requests, {this.answers = const {}}) : super(appConfig: const AppConfig.test());

  final List<RequestOptions> requests;
  final Map<String, Object> answers;

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) {
    final apiClient = super.createApiClient(secureStorage, onSessionExpired: onSessionExpired);
    // MockInterceptor comes last and answers in place of the server, so the recorder and the stub go right before it.
    final interceptors = apiClient.instance.interceptors;
    interceptors.insert(interceptors.length - 1, _RequestRecorder(requests));
    interceptors.insert(interceptors.length - 1, _StubInterceptor(answers));
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

/// Answers a GET of a path in [answers] with that body as JSON, as a server holding other data than the mock would.
class _StubInterceptor extends Interceptor {
  _StubInterceptor(this.answers);

  final Map<String, Object> answers;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final answer = answers[options.path];
    if (options.method == 'GET' && answer != null) {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: jsonEncode(answer)), true);
    } else {
      handler.next(options);
    }
  }
}
