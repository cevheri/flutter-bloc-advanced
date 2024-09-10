import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../configuration/environment.dart';
import '../../utils/app_constants.dart';
import '../http_utils.dart';
import '../models/change_password.dart';
import '../models/user.dart';
import 'package:flutter/services.dart';

class AccountRepository {
  AccountRepository();

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

  //TODO if (ProfileConstants.isProduction) {}
  Future<int> changePassword(
    PasswordChangeDTO passwordChangeDTO,
  ) async {
    if (ProfileConstants.isProduction) {
      final authenticateRequest = await HttpUtils.postRequest<PasswordChangeDTO>("/account/change-password", passwordChangeDTO);
      return authenticateRequest.statusCode;
    } else {
      return 200;
    }
  }


  //TODO if (ProfileConstants.isProduction) {}
  Future<int> resetPassword(String mailAddress) async {
    if (ProfileConstants.isProduction) {
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
    } else {
      HttpUtils.addCustomHttpHeader('Content-Type', 'text/plain');
      HttpUtils.addCustomHttpHeader('Accept', '*/*');
      return 200;
    }
  }

  //TODO if (ProfileConstants.isProduction) {}
  Future<User> getAccount() async {
    if (ProfileConstants.isProduction) {
      final response = await HttpUtils.getRequest("/account");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var result = JsonMapper.deserialize<User>(response)!;
      await prefs.setString('role', result.authorities?[0] ?? "");
      AppConstants.role = prefs.getString('role') ?? "";
      return result;
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var result = JsonMapper.deserialize<User>(await rootBundle.loadString('assets/mock/account.json'))!;
      await prefs.setString('role', result.authorities?[0] ?? "");
      AppConstants.role = prefs.getString('role') ?? "";
      return result;
    }
  }

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

  updateAccount(User account) {
    return HttpUtils.putRequest<User>("/account", account);
  }

  deleteAccount() {
    return HttpUtils.deleteRequest("/account");
  }
}
