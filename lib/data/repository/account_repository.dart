import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import '../http_utils.dart';
import '../models/user.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Account repository that handles all the account related operations
/// register, login, logout, getAccount, saveAccount, updateAccount
///
/// This class is responsible for all the account related operations
class AccountRepository {
  /// Register account method that registers a new user
  Future<String?> registerRemote(User newUser) async {
    final registerRequest = await HttpUtils.postRequest<User>("/register", newUser);

    String? result;

    if (registerRequest.statusCode == 400) {
      result = registerRequest.headers[HttpUtils.errorHeader];
    } else {
      result = HttpUtils.successResult;
    }

    return result;
  }

  /// Retrieve current account method that retrieves the current user
  Future<User> getAccountRemote() async {
    final saveRequest = await HttpUtils.getRequest("/account");
    return JsonMapper.deserialize<User>(saveRequest.body)!;
  }

  // get account from local json
  Future<User> getAccount() async {

    try {
      // read json file from ./mock/users.json
      // String content = await File('assets/mock/users.json').readAsString();
      String content = await rootBundle.loadString('assets/mock/users.json');
      // deserialize json to User object
      return JsonMapper.deserialize<User>(content)!;
    } catch (e) {
      print(e);
      return User();
    }
  }

  /// Save account method that saves the current user
  ///
  /// @param account the user object
  Future<String?> saveAccount(User account) async {
    final saveRequest = await HttpUtils.postRequest<User>("/account", account);
    String? result;
    if (saveRequest.statusCode != 200) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result;
  }

  /// Update account method that updates the current user
  ///
  /// @param account the user object
  updateAccount(User account) {
    return HttpUtils.putRequest<User>("/account", account);
  }

  /// Delete current account method that deletes the current user
  deleteAccount() {
    return HttpUtils.deleteRequest("/account");
  }
}
