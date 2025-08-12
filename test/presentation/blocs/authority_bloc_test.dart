import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/authority.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'authority_bloc_test.mocks.dart';

/// BLoc Test for AuthorityBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([AuthorityRepository])
void main() {
  //region setup
  late AuthorityRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockAuthorityRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion setup

  //region state
  /// Authority State Tests
  group("AuthorityState", () {
    const authorities = ["test"];
    const status = AuthorityStatus.initial;

    test("supports value comparisons", () {
      expect(
        const AuthorityState(authorities: authorities, status: status),
        const AuthorityState(authorities: authorities, status: status),
      );
    });

    test("AuthorityInitialState", () {
      expect(const AuthorityInitialState(), const AuthorityInitialState());
    });

    test("AuthorityLoadInProgressState", () {
      expect(const AuthorityLoadingState(), const AuthorityLoadingState());
    });

    test("AuthorityLoadSuccessState", () {
      expect(
        const AuthorityLoadSuccessState(authorities: authorities),
        const AuthorityLoadSuccessState(authorities: authorities),
      );
    });

    test("AuthorityLoadFailureState", () {
      expect(const AuthorityLoadFailureState(message: "test"), const AuthorityLoadFailureState(message: "test"));
    });
    test("AuthorityState copyWith", () {
      expect(const AuthorityState().copyWith(), const AuthorityState());
      expect(const AuthorityState().copyWith(authorities: authorities), const AuthorityState(authorities: authorities));
      expect(
        const AuthorityState().copyWith(status: AuthorityStatus.success),
        const AuthorityState(status: AuthorityStatus.success),
      );
    });
    test("AuthorityState stringify", () {
      expect(const AuthorityState().stringify, true);
    });
    test("AuthorityState props", () {
      expect(const AuthorityState().props, [AuthorityStatus.initial, []]);
      expect(const AuthorityState(authorities: authorities).props, [AuthorityStatus.initial, authorities]);

      expect(const AuthorityInitialState().props, [AuthorityStatus.initial, []]);
      expect(const AuthorityLoadingState().props, [AuthorityStatus.loading, []]);
      expect(const AuthorityLoadSuccessState(authorities: authorities).props, [AuthorityStatus.success, authorities]);
      expect(const AuthorityLoadFailureState(message: "test").props, [AuthorityStatus.failure, "test"]);
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
      expect(AuthorityBloc(repository: repository).state, initialState);
    });

    group("AuthorityLoad", () {
      const authorities = [Authority(name: "test")];
      final authoritiesMap = authorities.map((e) => e.name).toList();
      method() => repository.list();
      Future<List<String?>> output = Future<List<String?>>.value(authoritiesMap);
      const event = AuthorityLoad();
      const loadingState = AuthorityLoadingState();
      final successState = AuthorityLoadSuccessState(authorities: authoritiesMap);
      const failureState = AuthorityLoadFailureState(message: "Exception: Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<AuthorityBloc, AuthorityState>(
        "emits [loading, success] when load is successful",
        setUp: () => when(method()).thenAnswer((_) => output),
        build: () => AuthorityBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<AuthorityBloc, AuthorityState>(
        "emits [loading, failure] when load is unsuccessful",
        setUp: () => when(method()).thenThrow(Exception("Error")),
        build: () => AuthorityBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });
}
