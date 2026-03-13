import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/usecases/load_dashboard_usecase.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIDashboardRepository mockRepo;
  late LoadDashboardUseCase useCase;

  setUp(() {
    mockRepo = MockIDashboardRepository();
    useCase = LoadDashboardUseCase(mockRepo);
  });

  final dashboardEntity = DashboardEntity(
    summary: const [DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5)],
    activities: [
      DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: DateTime(2024), type: 'auth'),
    ],
    quickActions: const [DashboardQuickActionEntity(id: '1', label: 'Add User', icon: 'person_add')],
  );

  test('returns Success with dashboard data', () async {
    when(() => mockRepo.fetch()).thenAnswer((_) async => Success(dashboardEntity));

    final result = await useCase.call();

    expect(result, isA<Success<DashboardEntity>>());
    verify(() => mockRepo.fetch()).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.fetch()).thenAnswer((_) async => const Failure(NetworkError('No internet')));

    final result = await useCase.call();

    expect(result, isA<Failure<DashboardEntity>>());
  });
}
