@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';

void main() {
  late MockIUserRepository userRepository;
  late MockAuthorityRepository authorityRepository;

  setUp(() async {
    userRepository = MockIUserRepository();
    authorityRepository = MockAuthorityRepository();
    TestEnv.authenticate();
    await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_ADMIN']);
  });

  void stubRoles(Result<List<String>> result) {
    when(() => authorityRepository.list()).thenAnswer((_) async => result);
  }

  Future<void> open(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      App(language: 'en', dependencies: _RepositoryDependencies(userRepository, authorityRepository)),
    );
    await tester.pumpAndSettle();
    final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
    router.go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('the role filter shows that the roles could not be loaded and loads them again', (tester) async {
    stubRoles(const Failure(NetworkError('Authority service unavailable')));
    await open(tester, ApplicationRoutesConstants.userList);

    expect(find.text(S.current.authorities_load_failed), findsOneWidget);
    expect(find.text('Authority service unavailable'), findsNothing);

    stubRoles(const Success(['ROLE_ADMIN', 'ROLE_USER']));
    await tester.tap(find.byKey(const Key('authoritiesRetryButtonKey')));
    await tester.pumpAndSettle();

    expect(find.text(S.current.authorities_load_failed), findsNothing);
    expect(find.byKey(const Key('userEditorAuthoritiesFieldKey')), findsOneWidget);
  });

  testWidgets('a new user is not saved without a role when the roles could not be loaded', (tester) async {
    stubRoles(const Failure(NetworkError('Authority service unavailable')));
    when(() => userRepository.create(any())).thenAnswer((_) async => const Success(UserEntity(id: '8')));
    await open(tester, ApplicationRoutesConstants.userNew);

    expect(find.text(S.current.authorities_load_failed), findsOneWidget);

    await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'ada.lovelace');
    await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Ada');
    await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Lovelace');
    await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'ada.lovelace@example.com');
    await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
    await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
    await tester.pumpAndSettle();

    verifyNever(() => userRepository.create(any()));
    expect(find.text(S.current.required_field), findsOneWidget);
  });

  group('while the roles are loading', () {
    late Completer<Result<List<String>>> roles;

    // Pumps frames instead of settling, which a field that shows the roles loading would never do.
    Future<void> openWhileRolesLoad(WidgetTester tester, String location) async {
      // Created in the test body: completing a Completer from setUp would not resume the test's fake-async zone.
      roles = Completer();
      when(() => authorityRepository.list()).thenAnswer((_) => roles.future);
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        App(language: 'en', dependencies: _RepositoryDependencies(userRepository, authorityRepository)),
      );
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(location);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.tap(find.byKey(const Key('userEditorSubmitButtonKey')));
      await tester.pump();
    }

    // Lets the roles arrive so nothing is left running when the test ends.
    Future<void> finishLoadingRoles(WidgetTester tester) async {
      roles.complete(const Success(['ROLE_ADMIN', 'ROLE_USER']));
      await tester.pumpAndSettle();
    }

    testWidgets('a new user is not saved without a role', (tester) async {
      when(() => userRepository.create(any())).thenAnswer((_) async => const Success(UserEntity(id: '8')));
      await openWhileRolesLoad(tester, ApplicationRoutesConstants.userNew);

      await tester.enterText(find.byKey(const Key('userEditorLoginFieldKey')), 'ada.lovelace');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Ada');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Lovelace');
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'ada.lovelace@example.com');
      await tester.pump();
      await save(tester);

      verifyNever(() => userRepository.create(any()));
      expect(find.text(S.current.required_field), findsOneWidget);

      await finishLoadingRoles(tester);
    });

    testWidgets('an edited user is saved with the role it has', (tester) async {
      const grace = UserEntity(
        id: '7',
        login: 'grace.hopper',
        firstName: 'Grace',
        lastName: 'Hopper',
        email: 'grace.hopper@example.com',
        activated: true,
        authorities: ['ROLE_USER'],
      );
      when(() => userRepository.retrieve('grace.hopper')).thenAnswer((_) async => const Success(grace));
      when(() => userRepository.update(any())).thenAnswer((_) async => const Success(grace));
      await openWhileRolesLoad(tester, '/user/grace.hopper/edit');

      await save(tester);

      verify(
        () => userRepository.update(
          any(that: isA<UserEntity>().having((user) => user.authorities, 'authorities', ['ROLE_USER'])),
        ),
      ).called(1);

      await finishLoadingRoles(tester);
    });
  });
}

/// Mock-mode app dependencies whose users and roles are served by the given repositories.
class _RepositoryDependencies extends AppDependencies {
  const _RepositoryDependencies(this.userRepository, this.authorityRepository);

  final IUserRepository userRepository;
  final IAuthorityRepository authorityRepository;

  @override
  IUserRepository createUserRepository(ApiClient apiClient) => userRepository;

  @override
  IAuthorityRepository createAuthorityRepository(ApiClient apiClient) => authorityRepository;
}
