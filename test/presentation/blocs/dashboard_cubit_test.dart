import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/data/repository/dashboard_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/dashboard/bloc/dashboard_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

class _FakeDashboardRepositorySuccess implements DashboardRepository {
  @override
  Future<DashboardModel> fetch() async {
    const json =
        '{"summary":[{"id":"leads","label":"Leads","value":120,"trend":8}],"activities":[],"quick_actions":[{"id":"qa1","label":"New Lead","icon":"person_add"}] }';
    return DashboardModel.fromJsonString(json);
  }
}

class _FakeDashboardRepositoryFailure implements DashboardRepository {
  @override
  Future<DashboardModel> fetch() => Future.error(Exception('load failed'));
}

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('DashboardCubit', () {
    test('initial state is initial', () {
      final cubit = DashboardCubit(repository: _FakeDashboardRepositorySuccess());
      expect(cubit.state.status, DashboardStatus.initial);
      cubit.close();
    });

    blocTest<DashboardCubit, DashboardState>(
      'emits [loading, loaded] with model when fetch succeeds',
      build: () => DashboardCubit(repository: _FakeDashboardRepositorySuccess()),
      act: (cubit) => cubit.load(),
      expect: () => [
        const DashboardState.loading(),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loaded)
            .having((s) => s.model, 'model', isNotNull),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [loading, error] when fetch fails',
      build: () => DashboardCubit(repository: _FakeDashboardRepositoryFailure()),
      act: (cubit) => cubit.load(),
      expect: () => [
        const DashboardState.loading(),
        isA<DashboardState>().having((s) => s.status, 'status', DashboardStatus.error),
      ],
    );
  });
}
