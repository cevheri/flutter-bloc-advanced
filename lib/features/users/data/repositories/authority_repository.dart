import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class AuthorityRepositoryImpl implements IAuthorityRepository {
  AuthorityRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  static final _log = AppLogger.getLogger('AuthorityRepository');

  final String _resource = 'authorities';

  @override
  Future<Result<List<String>>> list() async {
    _log.debug('BEGIN:getAuthorities repository start');
    try {
      final queryParams = {'sort': 'name'};
      final response = await _apiClient.get('/$_resource', queryParams: queryParams);
      final result = Authority.fromJsonStringList(response.data!);
      final nonNullList = result.whereType<String>().toList();
      _log.debug('END:getAuthorities successful - response list size: {}', [nonNullList.length]);
      return Success(nonNullList);
    } on UnauthorizedException catch (e) {
      _log.error('END:getAuthorities auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getAuthorities validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getAuthorities network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getAuthorities unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
