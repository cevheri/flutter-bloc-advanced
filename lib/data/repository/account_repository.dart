import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:http/http.dart';

import '../../utils/app_constants.dart';
import '../http_utils.dart';
import '../models/change_password.dart';
import '../models/user.dart';

class AccountRepository {
  AccountRepository();

  Future<Response> register(User newUser) async {
    debugPrint("register repository start");
    final registerRequest = await HttpUtils.postRequest<User>("/register", newUser);
    return registerRequest;
  }

  Future<int> changePassword(PasswordChangeDTO passwordChangeDTO) async {
    debugPrint("changePassword repository start");
    final authenticateRequest =
        await HttpUtils.postRequest<PasswordChangeDTO>("/account/change-password", passwordChangeDTO);
    var result = authenticateRequest.statusCode;
    debugPrint("changePassword successful - response: $result");
    return result;
  }

  Future<int> resetPassword(String mailAddress) async {
    debugPrint("resetPassword repository start");
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    HttpUtils.addCustomHttpHeader('Accept', '*/*');
    final resetRequest = await HttpUtils.postRequest<String>("/account/reset-password/init", mailAddress);
    debugPrint("resetPassword successful - response: ${resetRequest.statusCode}");
    return resetRequest.statusCode;
  }

  Future<User> getAccount() async {
    debugPrint("getAccount repository start");
    final response = await HttpUtils.getRequest("/account");

    var result = JsonMapper.deserialize<User>(response)!;
    saveStorage(role: result.authorities?[0] ?? "");
    debugPrint("getAccount successful - response : $response}");
    return result;
  }

  Future<String?> saveAccount(User user) async {
    debugPrint("saveAccount repository start");
    final saveRequest = await HttpUtils.postRequest<User>("/account", user);
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
    var result = await HttpUtils.putRequest<User>("/account", account);
    debugPrint("updateAccount successful - response : ${result.body.toString()}");
    return result;
  }

  deleteAccount(int id) async {
    debugPrint("deleteAccount repository start");
    var result = await HttpUtils.deleteRequest("/account/$id");
    debugPrint("deleteAccount successful - response : ${result.body.toString()}");
    return result;
  }
}
