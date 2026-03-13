import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class AccountRepository implements IAccountRepository {
  static final _log = AppLogger.getLogger('AccountRepository');

  static const _resource = 'account';
  static const userIdNotNull = 'User id not null';

  @override
  Future<Result<UserEntity>> register(UserEntity newUser) async {
    _log.debug('BEGIN:register repository start : {}', [newUser.toString()]);
    try {
      if (newUser.email == null || newUser.email!.isEmpty) {
        return const Failure(ValidationError('User email is required'));
      }
      var user = newUser;
      if (user.login == null || user.login!.isEmpty) {
        user = user.copyWith(login: user.email);
      }
      if (user.langKey == null || user.langKey!.isEmpty) {
        user = user.copyWith(langKey: 'en');
      }
      user = user.copyWith(authorities: ['ROLE_USER']);
      final response = await ApiClient.post<User>('/register', User.fromEntity(user));
      final decoded = ApiClient.decodeUTF8(response.data!);
      final result = User.fromJsonString(decoded);
      if (result == null) {
        return const Failure(ServerError('Register response is null'));
      }
      _log.debug('END:register successful');
      return Success(result);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('register error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO) async {
    _log.debug('BEGIN:changePassword repository start : {}', [passwordChangeDTO.toString()]);
    try {
      if (passwordChangeDTO.currentPassword == null ||
          passwordChangeDTO.currentPassword!.isEmpty ||
          passwordChangeDTO.newPassword == null ||
          passwordChangeDTO.newPassword!.isEmpty) {
        return const Failure(ValidationError('Current password and new password are required'));
      }
      final response = await ApiClient.post<PasswordChangeDTO>('/$_resource/change-password', passwordChangeDTO);
      if ((response.statusCode ?? 0) < 400) {
        _log.debug('END:changePassword successful');
        return const Success(null);
      }
      return Failure(ServerError('Change password failed with status: ${response.statusCode}'));
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('changePassword error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> resetPassword(String mailAddress) async {
    _log.debug('BEGIN:resetPassword repository start : {}', [mailAddress]);
    try {
      if (mailAddress.isEmpty) {
        return const Failure(ValidationError('Mail address is required'));
      }
      if (!mailAddress.contains('@') || !mailAddress.contains('.')) {
        return const Failure(ValidationError('Mail address is invalid'));
      }
      final response = await ApiClient.post<String>(
        '/$_resource/reset-password/init',
        mailAddress,
        headers: {'Accept': 'application/json, text/plain, */*'},
        contentType: 'text/plain',
      );
      if ((response.statusCode ?? 0) < 400) {
        _log.debug('END:resetPassword successful');
        return const Success(null);
      }
      return Failure(ServerError('Reset password failed with status: ${response.statusCode}'));
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('resetPassword error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<UserEntity>> getAccount() async {
    _log.debug('BEGIN:getAccount repository start');
    try {
      final response = await ApiClient.get('/$_resource');
      final decoded = ApiClient.decodeUTF8(response.data!);
      final parsed = User.fromJsonString(decoded);
      if (parsed == null) {
        return const Failure(ServerError('Account response is null'));
      }
      final result = parsed;
      _log.debug('END:getAccount successful - response.body: {}', [result.toString()]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('getAccount error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    _log.debug('BEGIN:saveAccount repository start : {}', [user.toString()]);
    try {
      if (user.id == null || user.id!.isEmpty) {
        return const Failure(ValidationError(userIdNotNull));
      }
      final updatedUser = user.copyWith(langKey: user.langKey ?? 'en');
      final response = await ApiClient.post<User>('/$_resource', User.fromEntity(updatedUser));
      final decoded = ApiClient.decodeUTF8(response.data!);
      final parsed = User.fromJsonString(decoded);
      if (parsed == null) {
        return const Failure(ServerError('Update account response is null'));
      }
      final result = parsed;
      _log.debug('END:saveAccount successful');
      return Success(result);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('update error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    _log.debug('BEGIN:deleteAccount repository start : {}', [id]);
    try {
      if (id.isEmpty) {
        return const Failure(ValidationError(userIdNotNull));
      }
      final response = await ApiClient.delete('/$_resource/$id');
      _log.debug('END:deleteAccount successful - response.status: {}', [response.statusCode]);
      if (response.statusCode == 204) {
        return const Success(null);
      }
      return Failure(ServerError('Delete account failed with status: ${response.statusCode}'));
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e, st) {
      _log.error('delete error: {}', [e.toString()]);
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }

  AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('no internet')) return NetworkError(e.toString());
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return UnknownError(e.toString());
  }
}
