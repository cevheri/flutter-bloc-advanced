import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

/// Production API implementation for dashboard data.
class DashboardApiRepository implements IDashboardRepository {
  static final _log = AppLogger.getLogger('DashboardApiRepository');

  @override
  Future<Result<DashboardEntity>> fetch() async {
    _log.debug('BEGIN:fetch dashboard from API');
    try {
      final response = await ApiClient.get('/dashboard');
      final result = DashboardModel.fromJsonString(response.data!);
      _log.debug('END:fetch dashboard successful');
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('Dashboard fetch auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('Dashboard fetch network error: {}', [e.toString()]);
      final message = e.toString().toLowerCase();
      if (message.contains('timeout')) {
        return Failure(TimeoutError(e.toString()));
      }
      return Failure(NetworkError(e.toString()));
    } catch (e, st) {
      _log.error('Dashboard fetch unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }
}
