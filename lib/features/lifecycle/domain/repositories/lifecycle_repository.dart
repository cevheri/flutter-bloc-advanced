import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';

abstract class ILifecycleRepository {
  /// Fetch the remote app configuration.
  Future<Result<AppConfigEntity>> fetchAppConfig();
}
