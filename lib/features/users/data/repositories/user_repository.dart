import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/http/http_utils.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/data/mappers/user_mapper.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class UserRepository implements IUserRepository {
  static final _log = AppLogger.getLogger('UserRepository');
  static const String _resource = 'users';
  static const String userIdRequired = 'User id is required';

  @override
  Future<UserEntity?> retrieve(String id) async {
    _log.debug('BEGIN:getUser repository start - id: {}', [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.getRequest('/admin/$_resource', pathParams: id);
    final response = UserMapper.toEntity(User.fromJsonString(httpResponse.body)!);
    _log.debug('END:getUser successful - response.body: {}', [response.toString()]);
    return response;
  }

  @override
  Future<UserEntity?> retrieveByLogin(String login) async {
    _log.debug('BEGIN:getUserByLogin repository start - login: {}', [login]);
    if (login.isEmpty) {
      throw BadRequestException('User login is required');
    }
    final httpResponse = await HttpUtils.getRequest('/admin/$_resource', pathParams: login);
    final response = UserMapper.toEntity(User.fromJsonString(httpResponse.body)!);
    _log.debug('END:getUserByLogin successful - response.body: {}', [response.toString()]);
    return response;
  }

  @override
  Future<UserEntity?> create(UserEntity user) async {
    _log.debug('BEGIN:createUser repository start : {}', [user.toString()]);
    if (user.login == null || user.login!.isEmpty) {
      throw BadRequestException('User login is required');
    }
    if (user.email == null || user.email!.isEmpty) {
      throw BadRequestException('User email is required');
    }
    final httpResponse = await HttpUtils.postRequest<User>('/admin/$_resource', UserMapper.toModel(user));
    final response = User.fromJsonString(httpResponse.body);
    _log.debug('END:createUser successful');
    return response == null ? null : UserMapper.toEntity(response);
  }

  @override
  Future<UserEntity?> update(UserEntity user) async {
    _log.debug('BEGIN:updateUser repository start : {}', [user.toString()]);
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.putRequest<User>('/admin/$_resource', UserMapper.toModel(user));
    final response = User.fromJsonString(httpResponse.body);
    _log.debug('END:updateUser successful');
    return response == null ? null : UserMapper.toEntity(response);
  }

  @override
  Future<List<UserEntity>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async {
    _log.debug('BEGIN:getUsers repository start - page: {}, size: {}, sort: {}', [page, size, sort]);
    final queryParams = {'page': page.toString(), 'size': size.toString(), 'sort': sort.join('&sort=')};
    final httpResponse = await HttpUtils.getRequest('/admin/$_resource', queryParams: queryParams);
    final response = UserMapper.toEntityList(User.fromJsonStringList(httpResponse.body));
    _log.debug('END:getUsers successful - response list size: {}', [response.length]);
    return response;
  }

  @override
  Future<List<UserEntity>> listByAuthority(int page, int size, String authority) async {
    _log.debug('BEGIN:findUserByAuthority repository start - page: {}, size: {}, authority: {}', [
      page,
      size,
      authority,
    ]);
    final queryParams = {'page': page.toString(), 'size': size.toString()};
    final response = await HttpUtils.getRequest(
      '/admin/$_resource/authorities',
      pathParams: authority,
      queryParams: queryParams,
    );
    final result = UserMapper.toEntityList(User.fromJsonStringList(response.body));
    _log.debug('END:findUserByAuthority successful - response list size: {}', [result.length]);
    return result;
  }

  @override
  Future<List<UserEntity>> listByNameAndRole(int page, int size, String name, String authority) async {
    _log.debug('BEGIN:findUserByName repository start - page: {}, size: {}, name: {}, authority: {}', [
      page,
      size,
      name,
      authority,
    ]);
    final queryParams = {'page': page.toString(), 'size': size.toString(), 'name': name, 'authority': authority};
    final response = await HttpUtils.getRequest('/admin/$_resource/filter', queryParams: queryParams);
    final result = UserMapper.toEntityList(User.fromJsonStringList(response.body));
    _log.debug('END:findUserByName successful - response list size: {}', [result.length]);
    return result;
  }

  @override
  Future<void> delete(String id) async {
    _log.debug('BEGIN:deleteUser repository start - id: {}', [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdRequired);
    }
    final httpResponse = await HttpUtils.deleteRequest('/admin/$_resource', pathParams: id);
    _log.debug('END:deleteUser successful - response status code: {}', [httpResponse.statusCode]);
  }
}
