import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class UserRepository implements IUserRepository {
  UserRepository(this._apiClient);

  final ApiClient _apiClient;

  static final _log = AppLogger.getLogger('UserRepository');
  static const String _resource = 'users';
  static const String userIdRequired = 'User id is required';
  static const String userLoginRequired = 'User login is required';

  @override
  Future<Result<UserEntity>> retrieve(String id) async {
    _log.debug('BEGIN:getUser repository start - id: {}', [id]);
    if (id.isEmpty) {
      return const Failure(ValidationError(userIdRequired));
    }
    try {
      final response = await _apiClient.get('/admin/$_resource', pathParams: id);
      final result = User.fromJsonString(response.data!)!;
      _log.debug('END:getUser successful - response.body: {}', [result]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getUser auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getUser validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getUser network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getUser unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> create(UserEntity user) async {
    _log.debug('BEGIN:createUser repository start : {}', [user]);
    if (user.login == null || user.login!.isEmpty) {
      return const Failure(ValidationError(userLoginRequired));
    }
    if (user.email == null || user.email!.isEmpty) {
      return const Failure(ValidationError('User email is required'));
    }
    try {
      final response = await _apiClient.post<User>('/admin/$_resource', User.fromEntity(user), idempotent: true);
      final result = User.fromJsonString(response.data!);
      _log.debug('END:createUser successful');
      if (result == null) {
        return const Failure(UnknownError('Failed to parse user response'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:createUser auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:createUser validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:createUser network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:createUser unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    _log.debug('BEGIN:updateUser repository start : {}', [user]);
    if (user.id == null || user.id!.isEmpty) {
      return const Failure(ValidationError(userIdRequired));
    }
    try {
      final response = await _apiClient.put<User>('/admin/$_resource', User.fromEntity(user));
      final result = User.fromJsonString(response.data!);
      _log.debug('END:updateUser successful');
      if (result == null) {
        return const Failure(UnknownError('Failed to parse user response'));
      }
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:updateUser auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:updateUser validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:updateUser network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:updateUser unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async {
    _log.debug('BEGIN:getUsers repository start - page: {}, size: {}, sort: {}', [page, size, sort]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString(), 'sort': sort.join('&sort=')};
      final response = await _apiClient.get('/admin/$_resource', queryParams: queryParams);
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:getUsers successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:getUsers auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:getUsers validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:getUsers network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:getUsers unknown error: {}', [e]);
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
      final response = await _apiClient.get(
        '/admin/$_resource/authorities',
        pathParams: authority,
        queryParams: queryParams,
      );
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:findUserByAuthority successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:findUserByAuthority auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:findUserByAuthority validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:findUserByAuthority network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:findUserByAuthority unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<UserEntity>>> listByName(int page, int size, String name) async {
    _log.debug('BEGIN:listByName repository start - page: {}, size: {}, name: {}', [page, size, name]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString(), 'name': name};
      final response = await _apiClient.get('/admin/$_resource/filter', queryParams: queryParams);
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:listByName successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:listByName auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:listByName validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:listByName network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:listByName unknown error: {}', [e]);
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
      final response = await _apiClient.get('/admin/$_resource/filter', queryParams: queryParams);
      final result = User.fromJsonStringList(response.data!);
      _log.debug('END:findUserByName successful - response list size: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:findUserByName auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:findUserByName validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:findUserByName network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:findUserByName unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String login) async {
    _log.debug('BEGIN:deleteUser repository start - login: {}', [login]);
    if (login.isEmpty) {
      return const Failure(ValidationError(userLoginRequired));
    }
    try {
      final response = await _apiClient.delete('/admin/$_resource', pathParams: login);
      _log.debug('END:deleteUser successful - response status code: {}', [response.statusCode]);
      return const Success(null);
    } on UnauthorizedException catch (e) {
      _log.error('END:deleteUser auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:deleteUser validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:deleteUser network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:deleteUser unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
