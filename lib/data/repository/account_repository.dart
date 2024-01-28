import 'dart:developer';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_constants.dart';
import '../http_utils.dart';
import '../models/change_password.dart';
import '../models/menu.dart';
import '../models/user.dart';

/// Account repository that handles all the account related operations
/// register, login, logout, getAccount, saveAccount, updateAccount
///
/// This class is responsible for all the account related operations
class AccountRepository {
  AccountRepository();


  /// Register account method that registers a new user
  Future<String?> register(User newUser) async {
    final registerRequest = await HttpUtils.postRequest<User>("/register", newUser);
    String? result;
    if (registerRequest.statusCode == 400) {
      result = registerRequest.headers[HttpUtils.errorHeader];
    } else {
      result = HttpUtils.successResult;
    }
    return result;
  }

  /// current account password change 
  Future<int> changePassword(
    PasswordChangeDTO passwordChangeDTO,
  ) async {
    final authenticateRequest = await HttpUtils.postRequest<PasswordChangeDTO>(
        "/account/change-password", passwordChangeDTO);
    return authenticateRequest.statusCode;
  }

  Future<int> resetPassword(String mailAddress) async {
    HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
    HttpUtils.addCustomHttpHeader('Accept', '*/*');
    final resetRequest = await HttpUtils.postRequest<String>("/account/reset-password/init", mailAddress);

    String? result;
    if (resetRequest.statusCode != 200) {
      if (resetRequest.headers[HttpUtils.errorHeader] != null) {
        result = resetRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }
    return resetRequest.statusCode;
  }


  /// Retrieve current account method that retrieves the current user
  Future<User> getAccount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final response = await HttpUtils.getRequest("/account");
    // var result = JsonMapper.deserialize<User>(response)!;
    var result = JsonMapper.deserialize<User>(await rootBundle.loadString('mock/account.json'))!;
    await prefs.setString('role', result.authorities?[0] ?? "");
    AppConstants.role = prefs.getString('role') ?? "";
    return result;
  }

  /// Save account method that saves the current user
  ///
  /// @param account the user object
  Future<String?> saveAccount(User user) async {
    final saveRequest = await HttpUtils.postRequest<User>("/account", user);
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

  //TODO not implemented yet in API
  /// Delete current account method that deletes the current user
  deleteAccount() {
    return HttpUtils.deleteRequest("/account");
  }

  Future<List<Menu>> getMenus() async {
    final menusRequest = await HttpUtils.get("/menus/current-user");
    log("getMenus: ${menusRequest}");
    return JsonMapper.deserialize<List<Menu>>(menusRequest)!;
  }
}
