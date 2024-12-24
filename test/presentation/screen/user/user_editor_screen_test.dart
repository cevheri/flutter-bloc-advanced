import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/editor/user_editor_screen.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/user_routes.dart';
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
  late UserBloc userBloc;
  late TestUtils testUtils;

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    mockUserRepository = MockUserRepository();
    userBloc = MockUserBloc();

    mockAuthorityBloc = MockAuthorityBloc();
    mockAuthorityRepository = MockAuthorityRepository();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
    UserRoutes.dispose();
  });

  Widget buildTestableWidget({
    required EditorFormMode mode,
    String? id,
  }) {
    // Initialize UserRoutes with mock objects
    UserRoutes.init(userBloc: userBloc, userRepository: mockUserRepository, authorityBloc: mockAuthorityBloc, authorityRepository: mockAuthorityRepository);

    final router = GoRouter(
      initialLocation: id != null ? '/user/${id}/${mode.name}' : '/user/new',
      routes: UserRoutes.routes,
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }

  group('UserEditorScreen Tests', () {
    testWidgets('Create Mode - Should render empty form', (tester) async {
      // ARRANGE
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.byKey(const Key('userEditorLoginFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorActivatedFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorAuthoritiesFieldKey')), findsOneWidget);
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

      when(mockUserRepository.getUser(userId)).thenAnswer((_) async => mockUser);
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(
        mode: EditorFormMode.edit,
        id: userId,
      ));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
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

      when(mockUserRepository.getUser(userId)).thenAnswer((_) async => mockUser);
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(
        mode: EditorFormMode.view,
        id: userId,
      ));
      await tester.pumpAndSettle();

      // ASSERT
      final loginField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('userEditorLoginFieldKey')),
          matching: find.byType(TextField),
        ),
      );
      expect(loginField.enabled, false);
    });

    testWidgets('Create Mode - Should validate form before submit', (tester) async {
      // ARRANGE
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('Create Mode - Should submit valid form', (tester) async {
      // ARRANGE
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      const newUser = User(
        login: 'newuser',
        firstName: 'New',
        lastName: 'User',
        email: 'new@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );

      when(mockUserRepository.create(any)).thenAnswer((_) async => newUser);

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.byKey(const Key('userEditorLoginFieldKey')),
        'newuser',
      );
      await tester.enterText(
        find.byKey(const Key('userEditorFirstNameFieldKey')),
        'New',
      );
      await tester.enterText(
        find.byKey(const Key('userEditorLastNameFieldKey')),
        'User',
      );
      await tester.enterText(
        find.byKey(const Key('userEditorEmailFieldKey')),
        'new@example.com',
      );

      // Submit form
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      verify(mockUserRepository.create(any)).called(1);
    });

    testWidgets('Should handle cancel button tap', (tester) async {
      // ARRANGE
      when(mockAuthorityBloc.state).thenReturn(
        const AuthorityLoadSuccessState(authorities: ['ROLE_ADMIN', 'ROLE_USER']),
      );

      // ACT
      await tester.pumpWidget(buildTestableWidget(mode: EditorFormMode.create));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('userEditorCancelButtonKey')));
      await tester.pumpAndSettle();

      // ASSERT
      // Verify navigation or state changes as needed
    });
  });
}
