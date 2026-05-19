import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';
import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../test_utils.dart';

/// BLoc Test for AuthorityBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
void main() {
  //region setup
  late IAuthorityRepository repository;
  late ListAuthoritiesUseCase useCase;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockAuthorityRepository();
    useCase = ListAuthoritiesUseCase(repository);
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion setup

  //region state
  /// Authority State Tests
  group("AuthorityState", () {
    const authorities = ["test"];

    test("AuthorityInitialState equals", () {
      expect(const AuthorityInitialState(), const AuthorityInitialState());
      expect(const AuthorityInitialState().props, const <Object?>[]);
    });

    test("AuthorityLoadingState equals", () {
      expect(const AuthorityLoadingState(), const AuthorityLoadingState());
      expect(const AuthorityLoadingState().props, const <Object?>[]);
    });

    test("AuthorityLoadSuccessState equals", () {
      expect(
        const AuthorityLoadSuccessState(authorities: authorities),
        const AuthorityLoadSuccessState(authorities: authorities),
      );
      expect(const AuthorityLoadSuccessState(authorities: authorities).props, const <Object?>[authorities]);
    });

    test("AuthorityLoadFailureState equals", () {
      expect(const AuthorityLoadFailureState(message: "test"), const AuthorityLoadFailureState(message: "test"));
      expect(const AuthorityLoadFailureState(message: "test").props, const <Object?>["test"]);
    });
  });

  //endregion state

  //region event
  /// Authority Event Tests
  group("AuthorityEvent", () {
    test("AuthorityEvent", () {
      expect(const AuthorityEvent(), const AuthorityEvent());
      expect(const AuthorityEvent().props, []);
    });

    test("AuthorityLoad", () {
      expect(const AuthorityLoad(), const AuthorityLoad());
      expect(const AuthorityLoad().props, []);
    });
  });
  //endregion event

  //region bloc
  /// Authority Bloc Tests
  group("AuthorityBloc", () {
    const initialState = AuthorityInitialState();
    test("initial state is AuthorityInitialState", () {
      expect(AuthorityBloc(listAuthoritiesUseCase: useCase).state, initialState);
    });

    group("AuthorityLoad", () {
      const authorities = [Authority(name: "test")];
      final authoritiesMap = authorities.map((e) => e.name).whereType<String>().toList();
      method() => repository.list();
      final output = Future<Result<List<String>>>.value(Success(authoritiesMap));
      const event = AuthorityLoad();
      const loadingState = AuthorityLoadingState();
      final successState = AuthorityLoadSuccessState(authorities: authoritiesMap);
      const failureState = AuthorityLoadFailureState(message: "Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<AuthorityBloc, AuthorityState>(
        "emits [loading, success] when load is successful",
        setUp: () => when(method).thenAnswer((_) => output),
        build: () => AuthorityBloc(listAuthoritiesUseCase: useCase),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<AuthorityBloc, AuthorityState>(
        "emits [loading, failure] when load is unsuccessful",
        setUp: () => when(method).thenAnswer((_) async => const Failure(UnknownError("Error"))),
        build: () => AuthorityBloc(listAuthoritiesUseCase: useCase),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });
}
