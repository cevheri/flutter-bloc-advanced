import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/authority.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class AuthorityRepositoryImpl implements IAuthorityRepository {
  static final _log = AppLogger.getLogger('AuthorityRepository');

  AuthorityRepositoryImpl();

  final String _resource = 'authorities';

  @override
  Future<Result<Authority>> create(Authority authority) async {
    _log.debug('BEGIN:createAuthority repository start : {}', [authority.toString()]);
    if (authority.name == null || authority.name!.isEmpty) {
      return const Failure(ValidationError('Authority name null'));
    }
    try {
      final response = await ApiClient.post<Authority>('/$_resource', authority);
      final result = Authority.fromJsonString(response.data!);
      _log.debug('END:createAuthority successful');
      if (result == null) {
        return const Failure(UnknownError('Failed to parse authority response'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:createAuthority auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:createAuthority validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:createAuthority network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:createAuthority unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> list() async {
    _log.debug('BEGIN:getAuthorities repository start');
    try {
      final queryParams = {'sort': 'name'};
      final response = await ApiClient.get('/$_resource', queryParams: queryParams);
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

  @override
  Future<Result<Authority>> retrieve(String id) async {
    _log.debug('BEGIN:getAuthority repository start - id: {}', [id]);
    if (id.isEmpty) {
      return const Failure(ValidationError('Authority id null'));
    }
    try {
      final response = await ApiClient.get('/$_resource', pathParams: id);
      final result = Authority.fromJsonString(response.data!);
      _log.debug('END:getAuthority successful - response.body: {}', [result.toString()]);
      if (result == null) {
        return const Failure(NotFoundError('Authority not found'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getAuthority auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getAuthority validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getAuthority network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getAuthority unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    _log.debug('BEGIN:deleteAuthority repository start - id: {}', [id]);
    if (id.isEmpty) {
      return const Failure(ValidationError('Authority id null'));
    }
    try {
      final response = await ApiClient.delete('/$_resource', pathParams: id);
      _log.debug('END:deleteAuthority successful - response status code: {}', [response.statusCode]);
      return const Success(null);
    } on UnauthorizedException catch (e) {
      _log.error('END:deleteAuthority auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:deleteAuthority validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:deleteAuthority network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:deleteAuthority unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
