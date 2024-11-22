import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/http_utils.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';

class AccountRepository {
  static final _log = AppLogger.getLogger("AccountRepository");

  AccountRepository();

  static const _resource = "account";
  static const userIdNotNull = "User id not null";

  Future<User?> register(User? newUser) async {
    _log.debug("BEGIN:register repository start : {}", [newUser.toString()]);
    if (newUser == null) {
      throw BadRequestException("User null");
    }
    if (newUser.email == null || newUser.email!.isEmpty || newUser.login == null || newUser.login!.isEmpty) {
      throw BadRequestException("User email or login null");
    }
    if (newUser.langKey == null || newUser.langKey!.isEmpty) {
      newUser = newUser.copyWith(langKey: "en");
    }
    // when user is registered, it is a normal user
    newUser = newUser.copyWith(authorities: ["ROLE_USER"]);
    final httpResponse = await HttpUtils.postRequest<User>("/register", newUser);
    var response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response);
    _log.debug("END:register successful");
    return result;
  }

  Future<int> changePassword(PasswordChangeDTO? passwordChangeDTO) async {
    _log.debug("BEGIN:changePassword repository start : {}", [passwordChangeDTO.toString()]);
    if (passwordChangeDTO == null) {
      throw BadRequestException("PasswordChangeDTO null");
    }
    if (passwordChangeDTO.currentPassword == null ||
        passwordChangeDTO.currentPassword!.isEmpty ||
        passwordChangeDTO.newPassword == null ||
        passwordChangeDTO.newPassword!.isEmpty) {
      throw BadRequestException("PasswordChangeDTO currentPassword or newPassword null");
    }
    final httpResponse = await HttpUtils.postRequest<PasswordChangeDTO>("/$_resource/change-password", passwordChangeDTO);
    var result = httpResponse.statusCode;
    _log.debug("END:changePassword successful");
    return result;
  }

  Future<int> resetPassword(String mailAddress) async {
    _log.debug("BEGIN:resetPassword repository start : {}", [mailAddress]);
    if (mailAddress.isEmpty) {
      throw BadRequestException("Mail address null");
    }
    //valida mail address
    if (!mailAddress.contains("@") || !mailAddress.contains(".")) {
      throw BadRequestException("Mail address invalid");
    }
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    HttpUtils.addCustomHttpHeader('Accept', '*/*');
    final httpResponse = await HttpUtils.postRequest<String>("/$_resource/reset-password/init", mailAddress);
    _log.debug("END:resetPassword successful");
    return httpResponse.statusCode;
  }

  Future<User> getAccount() async {
    _log.debug("BEGIN:getAccount repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource");
    var response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response)!;
    _log.debug("END:getAccount successful - response.body: {}", [result.toString()]);
    return result;
  }

  Future<User> saveAccount(User? user) async {
    _log.debug("BEGIN:saveAccount repository start : {}", [user.toString()]);
    if (user == null) {
      throw BadRequestException("User null");
    }
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    final httpResponse = await HttpUtils.postRequest<User>("/$_resource", user);
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response)!;
    _log.debug("END:saveAccount successful");
    return result;
  }

  Future<User> updateAccount(User account) async {
    _log.debug("BEGIN:updateAccount repository start : {}", [account.toString()]);
    if (account.id == null || account.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    final response = await HttpUtils.putRequest<User>("/$_resource", account);
    final result = User.fromJsonString(response.body.toString())!;
    _log.debug("END:updateAccount successful");
    return result;
  }

  Future<bool> deleteAccount(String id) async {
    _log.debug("BEGIN:deleteAccount repository start : {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    var result = await HttpUtils.deleteRequest("/$_resource/$id");
    _log.debug("END:deleteAccount successful - response.status: {}", [result.statusCode]);
    return result.statusCode == 204;
  }
}
