@Tags(['widget'])
library;

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
