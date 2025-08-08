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
    if (newUser.email == null || newUser.email!.isEmpty) {
      throw BadRequestException("User email null");
    }
    if (newUser.login == null || newUser.login!.isEmpty) {
      newUser = newUser.copyWith(login: newUser.email);
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
    final httpResponse = await HttpUtils.postRequest<PasswordChangeDTO>(
      "/$_resource/change-password",
      passwordChangeDTO,
    );
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
    //
    //sample usage for production
    // https://dhw-api.onrender.com/api/account/reset-password/init
    //curl 'https://dhw-api.onrender.com/api/account/reset-password/init' \
    //   -H 'accept: application/json, text/plain, */*' \
    //   -H 'accept-language: en-US,en;q=0.9,tr-TR;q=0.8,tr;q=0.7,az;q=0.6' \
    //   -H 'content-type: text/plain' \
    //   -H 'origin: https://dhw-api.onrender.com' \
    //   -H 'priority: u=1, i' \
    //   -H 'referer: https://dhw-api.onrender.com/account/reset/request' \
    //   -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
    //   -H 'sec-ch-ua-mobile: ?0' \
    //   -H 'sec-ch-ua-platform: "Linux"' \
    //   -H 'sec-fetch-dest: empty' \
    //   -H 'sec-fetch-mode: cors' \
    //   -H 'sec-fetch-site: same-origin' \
    //   -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
    //   --data-raw 'cevheribozoglan@gmail.com'
    HttpUtils.addCustomHttpHeader('Accept', 'application/json, text/plain, */*');
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    // final body = {"email": mailAddress};
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

  Future<User> update(User? user) async {
    _log.debug("BEGIN:saveAccount repository start : {}", [user.toString()]);
    if (user == null) {
      throw BadRequestException("User null");
    }
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    user = user.copyWith(langKey: user.langKey ?? "en");
    final httpResponse = await HttpUtils.postRequest<User>("/$_resource", user);
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response)!;
    _log.debug("END:saveAccount successful");
    return result;
  }

  Future<bool> delete(String id) async {
    _log.debug("BEGIN:deleteAccount repository start : {}", [id]);
    if (id.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    var result = await HttpUtils.deleteRequest("/$_resource/$id");
    _log.debug("END:deleteAccount successful - response.status: {}", [result.statusCode]);
    return result.statusCode == 204;
  }
}
