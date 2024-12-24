import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/city.dart';
import 'package:flutter_bloc_advance/data/repository/city_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/city/city.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'city_bloc_test.mocks.dart';

/// BLoc Test for AuthorityBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([CityRepository])
void main() {
  //region setup
  late CityRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockCityRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //endregion setup

  //region state
  /// City State Tests
  group("CityState", () {
    const cities = [City(id: "test", name: "test")];
    const status = CityStatus.initial;

    test("supports value comparisons", () {
      expect(const CityState(cities: cities, status: status), const CityState(cities: cities, status: status));
    });

    test("CityInitialState", () {
      expect(const CityInitialState(), const CityInitialState());
    });

    test("CityLoadInProgressState", () {
      expect(const CityLoadingState(), const CityLoadingState());
    });

    test("CityLoadSuccessState", () {
      expect(const CityLoadSuccessState(cities: cities), const CityLoadSuccessState(cities: cities));
    });

    test("CityLoadFailureState", () {
      expect(const CityLoadFailureState(message: "test"), const CityLoadFailureState(message: "test"));
    });
    test("CityState copyWith", () {
      expect(const CityState().copyWith(), const CityState());
      expect(const CityState().copyWith(cities: cities), const CityState(cities: cities));
    });
    test("CityState props", () {
      expect(const CityState().props, [CityStatus.initial, []]);
    });
    test("CityState stringify", () {
      expect(const CityState().stringify, true);
    });
    test("CityInitialState props", () {
      expect(const CityInitialState().props, [CityStatus.initial, []]);
    });
    test("CityLoadingState props", () {
      expect(const CityLoadingState().props, [CityStatus.loading, []]);
    });
    test("CityLoadSuccessState props", () {
      expect(const CityLoadSuccessState(cities: cities).props, [CityStatus.success, cities]);
    });
    test("CityLoadFailureState props", () {
      expect(const CityLoadFailureState(message: "test").props, [CityStatus.failure, "test"]);
    });
  });

  //endregion state

  //region event
  /// City Event Tests
  group("CityEvent", () {
    test("CityEvent", () {
      expect(const CityEvent(), const CityEvent());
    });
    test("CityEvent props", () {
      expect(const CityEvent().props, []);
    });
    test("CityLoadList", () {
      expect(const CityLoad(), const CityLoad());
    });
    test("CityLoadList props", () {
      expect(const CityLoad().props, []);
    });
  });

  //endregion event

  //region bloc
  /// City Bloc Tests
  group("CityBloc", () {
    const initialState = CityInitialState();
    test("initial state is CityInitialState", () {
      expect(CityBloc(repository: repository).state, initialState);
    });

    group("CityLoad", () {
      const input = [City(id: "test", name: "test")];
      final output = Future.value(input);
      method() => repository.list();
      const event = CityLoad();
      const loadingState = CityLoadingState();
      const successState = CityLoadSuccessState(cities: input);
      const failureState = CityLoadFailureState(message: "Exception: Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<CityBloc, CityState>(
        "emits [loading, success] when load is successful",
        setUp: () => when(method()).thenAnswer((_) => output),
        build: () => CityBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<CityBloc, CityState>(
        "emits [loading, failure] when load is unsuccessful",
        setUp: () => when(method()).thenThrow(Exception("Error")),
        build: () => CityBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });
}
