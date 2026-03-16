import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/models/app_config_model.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class LifecycleRepository implements ILifecycleRepository {
  static final _log = AppLogger.getLogger('LifecycleRepository');

  @override
  Future<Result<AppConfigEntity>> fetchAppConfig() async {
    _log.debug('Fetching app config');
    try {
      final response = await ApiClient.get('/app/config');
      final model = AppConfigModel.fromJsonString(response.data!);
      return Success(model);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout')) return Failure(TimeoutError(e.toString()));
      return Failure(NetworkError(e.toString()));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
