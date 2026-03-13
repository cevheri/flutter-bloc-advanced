import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class UserRepository implements IUserRepository {
  static final _log = AppLogger.getLogger('UserRepository');
  static const String _resource = 'users';
  static const String userIdRequired = 'User id is required';

  @override
  Future<Result<UserEntity>> retrieve(String id) async {
    _log.debug('BEGIN:getUser repository start - id: {}', [id]);
    if (id.isEmpty) {
      return const Failure(ValidationError(userIdRequired));
    }
    try {
      final response = await ApiClient.get('/admin/$_resource', pathParams: id);
      final result = User.fromJsonString(response.data!)!;
      _log.debug('END:getUser successful - response.body: {}', [result.toString()]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getUser auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getUser validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getUser network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getUser unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> retrieveByLogin(String login) async {
    _log.debug('BEGIN:getUserByLogin repository start - login: {}', [login]);
    if (login.isEmpty) {
      return const Failure(ValidationError('User login is required'));
    }
    try {
      final response = await ApiClient.get('/admin/$_resource', pathParams: login);
      final result = User.fromJsonString(response.data!)!;
      _log.debug('END:getUserByLogin successful - response.body: {}', [result.toString()]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getUserByLogin auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getUserByLogin validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getUserByLogin network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getUserByLogin unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> create(UserEntity user) async {
    _log.debug('BEGIN:createUser repository start : {}', [user.toString()]);
    if (user.login == null || user.login!.isEmpty) {
      return const Failure(ValidationError('User login is required'));
    }
    if (user.email == null || user.email!.isEmpty) {
      return const Failure(ValidationError('User email is required'));
    }
    try {
      final response = await ApiClient.post<User>('/admin/$_resource', User.fromEntity(user));
      final result = User.fromJsonString(response.data!);
      _log.debug('END:createUser successful');
      if (result == null) {
        return const Failure(UnknownError('Failed to parse user response'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:createUser auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:createUser validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:createUser network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:createUser unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    _log.debug('BEGIN:updateUser repository start : {}', [user.toString()]);
    if (user.id == null || user.id!.isEmpty) {
      return const Failure(ValidationError(userIdRequired));
    }
    try {
      final response = await ApiClient.put<User>('/admin/$_resource', User.fromEntity(user));
      final result = User.fromJsonString(response.data!);
      _log.debug('END:updateUser successful');
      if (result == null) {
        return const Failure(UnknownError('Failed to parse user response'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:updateUser auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:updateUser validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:updateUser network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:updateUser unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async {
    _log.debug('BEGIN:getUsers repository start - page: {}, size: {}, sort: {}', [page, size, sort]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString(), 'sort': sort.join('&sort=')};
      final response = await ApiClient.get('/admin/$_resource', queryParams: queryParams);
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:getUsers successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getUsers auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getUsers validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getUsers network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getUsers unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<UserEntity>>> listByAuthority(int page, int size, String authority) async {
    _log.debug('BEGIN:findUserByAuthority repository start - page: {}, size: {}, authority: {}', [
      page,
      size,
      authority,
    ]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString()};
      final response = await ApiClient.get(
        '/admin/$_resource/authorities',
        pathParams: authority,
        queryParams: queryParams,
      );
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:findUserByAuthority successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:findUserByAuthority auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:findUserByAuthority validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:findUserByAuthority network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:findUserByAuthority unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<UserEntity>>> listByNameAndRole(int page, int size, String name, String authority) async {
    _log.debug('BEGIN:findUserByName repository start - page: {}, size: {}, name: {}, authority: {}', [
      page,
      size,
      name,
      authority,
    ]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString(), 'name': name, 'authority': authority};
      final response = await ApiClient.get('/admin/$_resource/filter', queryParams: queryParams);
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:findUserByName successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:findUserByName auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:findUserByName validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:findUserByName network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:findUserByName unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    _log.debug('BEGIN:deleteUser repository start - id: {}', [id]);
    if (id.isEmpty) {
      return const Failure(ValidationError(userIdRequired));
    }
    try {
      final response = await ApiClient.delete('/admin/$_resource', pathParams: id);
      _log.debug('END:deleteUser successful - response status code: {}', [response.statusCode]);
      return const Success(null);
    } on UnauthorizedException catch (e) {
      _log.error('END:deleteUser auth error: {}', [e.toString()]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:deleteUser validation error: {}', [e.toString()]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:deleteUser network error: {}', [e.toString()]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:deleteUser unknown error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()));
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
