import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/usecases/fetch_app_config_usecase.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockILifecycleRepository mockRepo;
  late FetchAppConfigUseCase useCase;

  setUp(() {
    mockRepo = MockILifecycleRepository();
    useCase = FetchAppConfigUseCase(mockRepo);
  });

  const config = AppConfigEntity(minimumVersion: '1.0.0', maintenanceMode: false);

  test('returns Success with the app config', () async {
    when(() => mockRepo.fetchAppConfig()).thenAnswer((_) async => const Success(config));

    final result = await useCase.call();

    expect(result, const Success(config));
    verify(() => mockRepo.fetchAppConfig()).called(1);
  });

  test('returns Failure with the repository error', () async {
    when(() => mockRepo.fetchAppConfig()).thenAnswer((_) async => const Failure(NetworkError('No connection')));

    final result = await useCase.call();

    expect(result, isA<Failure<AppConfigEntity>>());
    expect((result as Failure).error, const NetworkError('No connection'));
  });
}
