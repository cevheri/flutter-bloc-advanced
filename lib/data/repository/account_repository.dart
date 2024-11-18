import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';

import '../http_utils.dart';
import '../models/change_password.dart';
import '../models/user.dart';

class AccountRepository {
  AccountRepository();

  final String _resource = "account";

  Future<User?> register(User newUser) async {
    debugPrint("register repository start");
    final httpResponse = await HttpUtils.postRequest<User>("/register", newUser);
    var response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    return User.fromJsonString(response);
  }

  Future<int> changePassword(PasswordChangeDTO passwordChangeDTO) async {
    debugPrint("changePassword repository start");
    final authenticateRequest = await HttpUtils.postRequest<PasswordChangeDTO>("/$_resource/change-password", passwordChangeDTO);
    var result = authenticateRequest.statusCode;
    debugPrint("changePassword successful - response: $result");
    return result;
  }

  Future<int> resetPassword(String mailAddress) async {
    debugPrint("resetPassword repository start");
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    HttpUtils.addCustomHttpHeader('Accept', '*/*');
    final resetRequest = await HttpUtils.postRequest<String>("/$_resource/reset-password/init", mailAddress);
    debugPrint("resetPassword successful - response: ${resetRequest.statusCode}");
    return resetRequest.statusCode;
  }

  Future<User> getAccount() async {
    debugPrint("BEGIN: getAccount repository");
    final httpResponse = await HttpUtils.getRequest("/$_resource");

    var response = HttpUtils.decodeUTF8(httpResponse.body.toString());
    debugPrint(" GET Request Method result : $response");

    var result = User.fromJsonString(response)!;
    saveStorage(roles: result.authorities);
    debugPrint("END: getAccount repository");
    return result;
  }

  Future<String?> saveAccount(User user) async {
    debugPrint("saveAccount repository start");
    final saveRequest = await HttpUtils.postRequest<User>("/$_resource", user);
    String? result;
    if (saveRequest.statusCode >= HttpStatus.badRequest) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }
    debugPrint("saveAccount successful - response : $result");
    return result;
  }

  updateAccount(User account) async {
    debugPrint("updateAccount repository start");
    var result = await HttpUtils.putRequest<User>("/$_resource", account);
    debugPrint("updateAccount successful - response : ${result.body.toString()}");
    return result;
  }

  deleteAccount(int id) async {
    debugPrint("deleteAccount repository start");
    var result = await HttpUtils.deleteRequest("/$_resource/$id");
    debugPrint("deleteAccount successful - response : ${result.body.toString()}");
    return result;
  }
}
