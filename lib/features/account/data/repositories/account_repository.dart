import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/http/http_utils.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/mappers/user_mapper.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class AccountRepository implements IAccountRepository {
  static final _log = AppLogger.getLogger('AccountRepository');

  static const _resource = 'account';
  static const userIdNotNull = 'User id not null';

  @override
  Future<UserEntity?> register(UserEntity? newUser) async {
    _log.debug('BEGIN:register repository start : {}', [newUser.toString()]);
    if (newUser == null) {
      throw BadRequestException('User null');
    }
    if (newUser.email == null || newUser.email!.isEmpty) {
      throw BadRequestException('User email null');
    }
    if (newUser.login == null || newUser.login!.isEmpty) {
      newUser = newUser.copyWith(login: newUser.email);
    }
    if (newUser.langKey == null || newUser.langKey!.isEmpty) {
      newUser = newUser.copyWith(langKey: 'en');
    }
    newUser = newUser.copyWith(authorities: ['ROLE_USER']);
    final httpResponse = await HttpUtils.postRequest<User>('/register', UserMapper.toModel(newUser));
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    final result = User.fromJsonString(response);
    _log.debug('END:register successful');
    return result == null ? null : UserMapper.toEntity(result);
  }

  @override
  Future<int> changePassword(PasswordChangeDTO? passwordChangeDTO) async {
    _log.debug('BEGIN:changePassword repository start : {}', [passwordChangeDTO.toString()]);
    if (passwordChangeDTO == null) {
      throw BadRequestException('PasswordChangeDTO null');
    }
    if (passwordChangeDTO.currentPassword == null ||
        passwordChangeDTO.currentPassword!.isEmpty ||
        passwordChangeDTO.newPassword == null ||
        passwordChangeDTO.newPassword!.isEmpty) {
      throw BadRequestException('PasswordChangeDTO currentPassword or newPassword null');
    }
    final httpResponse = await HttpUtils.postRequest<PasswordChangeDTO>(
      '/$_resource/change-password',
      passwordChangeDTO,
    );
    final result = httpResponse.statusCode;
    _log.debug('END:changePassword successful');
    return result;
  }

  @override
  Future<int> resetPassword(String mailAddress) async {
    _log.debug('BEGIN:resetPassword repository start : {}', [mailAddress]);
    if (mailAddress.isEmpty) {
      throw BadRequestException('Mail address null');
    }
    if (!mailAddress.contains('@') || !mailAddress.contains('.')) {
      throw BadRequestException('Mail address invalid');
    }
    HttpUtils.addCustomHttpHeader('Accept', 'application/json, text/plain, */*');
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    final httpResponse = await HttpUtils.postRequest<String>('/$_resource/reset-password/init', mailAddress);
    _log.debug('END:resetPassword successful');
    return httpResponse.statusCode;
  }

  @override
  Future<UserEntity> getAccount() async {
    _log.debug('BEGIN:getAccount repository start');
    final httpResponse = await HttpUtils.getRequest('/$_resource');
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    final result = UserMapper.toEntity(User.fromJsonString(response)!);
    _log.debug('END:getAccount successful - response.body: {}', [result.toString()]);
    return result;
  }

  @override
  Future<UserEntity> update(UserEntity? user) async {
    _log.debug('BEGIN:saveAccount repository start : {}', [user.toString()]);
    if (user == null) {
      throw BadRequestException('User null');
    }
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    user = user.copyWith(langKey: user.langKey ?? 'en');
    final httpResponse = await HttpUtils.postRequest<User>('/$_resource', UserMapper.toModel(user));
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    final result = UserMapper.toEntity(User.fromJsonString(response)!);
    _log.debug('END:saveAccount successful');
    return result;
  }

  @override
  Future<bool> delete(String id) async {
    _log.debug('BEGIN:deleteAccount repository start : {}', [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    final result = await HttpUtils.deleteRequest('/$_resource/$id');
    _log.debug('END:deleteAccount successful - response.status: {}', [result.statusCode]);
    return result.statusCode == 204;
  }
}
