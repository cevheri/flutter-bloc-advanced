import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/models/app_config_model.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class LifecycleRepository implements ILifecycleRepository {
  LifecycleRepository(this._apiClient);

  final ApiClient _apiClient;

  static final _log = AppLogger.getLogger('LifecycleRepository');

  @override
  Future<Result<AppConfigEntity>> fetchAppConfig() async {
    _log.debug('Fetching app config');
    try {
      final response = await _apiClient.get('/app/config');
      final model = AppConfigModel.fromJsonString(response.data!);
      return Success(model);
    } on UnauthorizedException catch (e) {
      _log.warn('fetchAppConfig auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      _log.warn('fetchAppConfig network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('fetchAppConfig unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  /// An untrusted certificate carries [AppErrorCode.networkCertInvalid], as in DynamicFormRepository, so it can be told
  /// apart from a dropped connection.
  static AppError _mapFetchDataException(FetchDataException e) {
    if (e is UntrustedCertificateException) {
      return NetworkError(e.toString(), code: AppErrorCode.networkCertInvalid.key);
    }
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
