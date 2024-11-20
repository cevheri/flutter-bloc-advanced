import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/http_utils.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';


class AccountRepository {
  AccountRepository();

  static const _resource = "account";
  static const userIdNotNull = "User id not null";

  Future<User?> register(User? newUser) async {
    debugPrint("register repository start");
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
    return User.fromJsonString(response);
  }

  Future<int> changePassword(PasswordChangeDTO? passwordChangeDTO) async {
    debugPrint("BEGIN:changePassword repository start");
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
    debugPrint("END:changePassword successful - response: $result");
    return result;
  }

  Future<int> resetPassword(String mailAddress) async {
    debugPrint("BEGIN:resetPassword repository start");
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
    debugPrint("END:resetPassword successful - response: ${httpResponse.statusCode}");
    return httpResponse.statusCode;
  }

  Future<User> getAccount() async {
    debugPrint("BEGIN:getAccount repository start");
    final httpResponse = await HttpUtils.getRequest("/$_resource");
    var response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response)!;
    debugPrint("END:getAccount successful - response : $response}");
    return result;
  }

  Future<User> saveAccount(User? user) async {
    debugPrint("BEGIN:saveAccount repository start");
    if (user == null) {
      throw BadRequestException("User null");
    }
    if (user.id == null || user.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    final httpResponse = await HttpUtils.postRequest<User>("/$_resource", user);
    final response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    var result = User.fromJsonString(response)!;
    debugPrint("END:saveAccount successful - response length : ${result.toString().length}");
    return result;
  }

  Future<User> updateAccount(User account) async {
    debugPrint("BEGIN:updateAccount repository start");
    if (account.id == null || account.id!.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    final response = await HttpUtils.putRequest<User>("/$_resource", account);
    final result = User.fromJsonString(response.body.toString())!;
    debugPrint("END:updateAccount successful - response.length : ${result.toString().length}");
    return result;
  }

  Future<bool> deleteAccount(String id) async {
    debugPrint("BEGIN:deleteAccount repository start");
    if (id.isEmpty) {
      throw BadRequestException(userIdNotNull);
    }
    var result = await HttpUtils.deleteRequest("/$_resource/$id");
    debugPrint("END:deleteAccount successful - response : ${result.body.toString()}");
    return result.statusCode == 204;
  }
}
