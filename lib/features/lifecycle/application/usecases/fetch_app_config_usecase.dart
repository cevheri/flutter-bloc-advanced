import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';

class FetchAppConfigUseCase {
  const FetchAppConfigUseCase(this._repository);

  final ILifecycleRepository _repository;

  Future<Result<AppConfigEntity>> call() {
    return _repository.fetchAppConfig();
  }
}
