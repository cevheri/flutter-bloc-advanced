import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/district.dart';
import 'package:flutter_bloc_advance/data/repository/district_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/district/district.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'district_bloc_test.mocks.dart';

/// BLoc Test for AuthorityBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([DistrictRepository])
void main() {
  //region setup
  late DistrictRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockDistrictRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //endregion setup

  //region state
  /// District State Tests
  group("DistrictState", () {
    const districts = [District(id: "test", name: "test")];
    const status = DistrictStatus.initial;

    test("supports value comparisons", () {
      expect(
        const DistrictState(districts: districts, status: status),
        const DistrictState(districts: districts, status: status),
      );
    });

    test("DistrictInitialState", () {
      expect(const DistrictInitialState(), const DistrictInitialState());
    });

    test("DistrictLoadInProgressState", () {
      expect(const DistrictLoadingState(), const DistrictLoadingState());
    });

    test("DistrictLoadSuccessState", () {
      expect(
        const DistrictLoadSuccessState(districts: districts),
        const DistrictLoadSuccessState(districts: districts),
      );
    });

    test("DistrictLoadFailureState", () {
      expect(const DistrictLoadFailureState(message: "test"), const DistrictLoadFailureState(message: "test"));
    });
    test("DistrictState copyWith", () {
      expect(const DistrictState().copyWith(), const DistrictState());
      expect(const DistrictState().copyWith(districts: districts), const DistrictState(districts: districts));
    });
    test("DistrictState props", () {
      expect(const DistrictState().props, [DistrictStatus.initial, []]);
    });
    test("DistrictState stringify", () {
      expect(const DistrictState().stringify, true);
    });
    test("DistrictInitialState props", () {
      expect(const DistrictInitialState().props, [DistrictStatus.initial, []]);
    });
    test("DistrictLoadingState props", () {
      expect(const DistrictLoadingState().props, [DistrictStatus.loading, []]);
    });
    test("DistrictLoadSuccessState props", () {
      expect(const DistrictLoadSuccessState(districts: districts).props, [DistrictStatus.success, districts]);
    });
    test("DistrictLoadFailureState props", () {
      expect(const DistrictLoadFailureState(message: "test").props, [DistrictStatus.failure, "test"]);
    });
  });

  //endregion state

  //region event
  /// District Event Tests
  group("DistrictEvent", () {
    test("DistrictEvent", () {
      expect(const DistrictEvent(), const DistrictEvent());
    });
    test("DistrictEvent props", () {
      expect(const DistrictEvent().props, []);
    });

    test("DistrictLoad", () {
      expect(const DistrictLoad(), const DistrictLoad());
    });
    test("DistrictLoadList props", () {
      expect(const DistrictLoad().props, []);
    });

    test("DistrictLoadList", () {
      expect(const DistrictLoadByCity(cityId: "test"), const DistrictLoadByCity(cityId: "test"));
    });
    test("DistrictLoadList props", () {
      expect(const DistrictLoadByCity(cityId: "test").props, ["test"]);
    });
  });

  //endregion event

  //region bloc
  /// District Bloc Tests
  group("DistrictBloc", () {
    const initialState = DistrictInitialState();
    test("initial state is DistrictInitialState", () {
      expect(DistrictBloc(repository: repository).state, initialState);
    });

    group("DistrictLoad", () {
      const input = [District(id: "test", name: "test")];
      final output = Future.value(input);
      method() => repository.list();
      const event = DistrictLoad();
      const loadingState = DistrictLoadingState();
      const successState = DistrictLoadSuccessState(districts: input);
      const failureState = DistrictLoadFailureState(message: "Exception: Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<DistrictBloc, DistrictState>(
        "emits [loading, success] when load is successful",
        setUp: () => when(method()).thenAnswer((_) => output),
        build: () => DistrictBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<DistrictBloc, DistrictState>(
        "emits [loading, failure] when load is unsuccessful",
        setUp: () => when(method()).thenThrow(Exception("Error")),
        build: () => DistrictBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });

    group("DistrictLoadByCity", () {
      const input = [District(id: "test", name: "test")];
      final output = Future.value(input);
      method() => repository.listByCity("test");
      const event = DistrictLoadByCity(cityId: "test");
      const loadingState = DistrictLoadingState();
      const successState = DistrictLoadSuccessState(districts: input);
      const failureState = DistrictLoadFailureState(message: "Exception: Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<DistrictBloc, DistrictState>(
        "emits [loading, success] when load is successful",
        setUp: () => when(method()).thenAnswer((_) => output),
        build: () => DistrictBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<DistrictBloc, DistrictState>(
        "emits [loading, failure] when load is unsuccessful",
        setUp: () => when(method()).thenThrow(Exception("Error")),
        build: () => DistrictBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });
  //endregion bloc
}
