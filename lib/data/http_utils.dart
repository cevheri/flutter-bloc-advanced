import 'dart:async';
import 'dart:convert' show Encoding, utf8;
import 'dart:developer';
import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/allowed_paths.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:http/http.dart' as http;

import 'app_api_exception.dart';

// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }

class HttpUtils {
  static final _log = AppLogger.getLogger("HttpUtils");
  static const successResult = 'success';
  static const keyForJWTToken = 'jwt-token';
  static const badRequestServerKey = 'error.400';
  static const errorServerKey = 'error.500';
  static const generalNoErrorKey = 'none';
  static const timeoutValue = 30;
  static const applicationJson = 'application/json';
  static const utf8Val = 'utf-8';
  static const noInternetConnectionError = 'No Internet connection';
  static const requestTimeoutError = 'Request timeout';
  static const _timeout = Duration(seconds: timeoutValue);
  static final _encoding = Encoding.getByName(utf8Val);
  static const _serOps = SerializationOptions(indent: '', ignoreDefaultMembers: true, ignoreNullMembers: true, ignoreUnknownTypes: true);

  ///   -H 'accept: application/json, text/plain, */*' \
  ///   -H 'content-type: application/json' \
  /// Default headers for all requests (can be overridden with [addCustomHttpHeader])
  static final _defaultHttpHeaders = {'Accept': applicationJson, 'Content-Type': applicationJson};

  static final _customHttpHeaders = <String, String>{};

  /// Add custom http headers when you need to override the default ones
  static void addCustomHttpHeader(String key, String value) {
    _log.debug("BEGIN: Adding custom headers {} : {}", [key, value]);
    log("add custom headers $key: $value");
    _customHttpHeaders[key] = value;
    _log.debug("END: Added custom headers");
  }

  static String decodeUTF8(String toEncode) {
    return utf8.decode(toEncode.runes.toList());
  }

  ///   -H 'accept: application/json, text/plain, */*' \
  ///   -H 'content-type: application/json' \

  static Future<Map<String, String>> headers() async {
    Map<String, String> headerParameters = <String, String>{};

    //custom http headers entries
    if (_customHttpHeaders.isNotEmpty) {
      log("custom headers");
      headerParameters.addAll(_customHttpHeaders);
      _customHttpHeaders.clear();
    } else {
      headerParameters.addAll(_defaultHttpHeaders);
      log("default headers : $_defaultHttpHeaders");
    }

    final jwtToken = await AppLocalStorage().read(StorageKeys.jwtToken.name);

    if (jwtToken != null) {
      headerParameters['Authorization'] = 'Bearer $jwtToken';
    } else {
      headerParameters.remove('Authorization');
    }

    return headerParameters;
  }

  static void checkUnauthorizedAccess(String endpoint, http.Response response) {
    if (response.statusCode == 401) {
      throw UnauthorizedException(response.body.toString());
    }
  }

  static Future<http.Response> postRequest<T>(String endpoint, T body, {Map<String, String>? headers}) async {
    debugPrint("BEGIN: POST Request Method start : ${ProfileConstants.api}$endpoint");

    /// if isMock is true, return mock data instead of making a request
    if (!ProfileConstants.isProduction) return await mockRequest('POST', endpoint);

    final headers = await HttpUtils.headers();
    String messageBody = "";

    if (headers['Content-Type'] == applicationJson) {
      messageBody = JsonMapper.serialize(body, _serOps);
    } else {
      messageBody = body as String;
    }

    final http.Response response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http.post(url, headers: headers, body: messageBody, encoding: _encoding).timeout(_timeout);
      checkUnauthorizedAccess(endpoint, response);
    } on SocketException catch (se) {
      debugPrint("Socket Exception: $se");
      throw FetchDataException(noInternetConnectionError);
    } on TimeoutException catch (toe) {
      debugPrint("Timeout Exception: $toe");
      throw FetchDataException(requestTimeoutError);
    }
    debugPrint("END: POST Request Method end : ${ProfileConstants.api}$endpoint");
    return response;
  }

  static Future<http.Response> getRequest(String endpoint) async {
    debugPrint("BEGIN: GET Request Method start : ${ProfileConstants.api}$endpoint");

    /// if isMock is true, return mock data instead of making a request
    if (!ProfileConstants.isProduction) return (await mockRequest('GET', endpoint));
    final http.Response response;
    final headers = await HttpUtils.headers();
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http.get(url, headers: headers).timeout(_timeout);
      checkUnauthorizedAccess(endpoint, response);
    } on SocketException {
      throw FetchDataException(noInternetConnectionError);
    } on TimeoutException {
      throw FetchDataException(requestTimeoutError);
    }
    debugPrint("END: GET Request Method end : ${ProfileConstants.api}$endpoint");
    return response;
  }

  // static Future<int> getRequestHeader(String endpoint) async {
  //   debugPrint(endpoint);
  //   var headers = await HttpUtils.headers();
  //   try {
  //     var result = await http
  //         .get(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers)
  //         .timeout(cont Duration(seconds: timeout));
  //     debugPrint(result.headers.toString());
  //     if (result.statusCode == 401) {
  //       throw UnauthorizedException(result.headers.toString());
  //     }
  //     Map<String, dynamic> pageable = <String, dynamic>{};
  //     pageable['x-total-count'] = result.headers['x-total-count'];
  //     int countOffers = int.parse(result.headers['x-total-count']!);
  //     return countOffers;
  //   } on SocketException {
  //     throw FetchDataException(noInternetConnectionError);
  //   } on TimeoutException {
  //     throw FetchDataException(requestTimeoutError);
  //   }
  // }

  static Future<http.Response> putRequest<T>(String endpoint, T body) async {
    debugPrint("BEGIN: PUT Request Method start : ${ProfileConstants.api}$endpoint");
    if (!ProfileConstants.isProduction) return await mockRequest('PUT', endpoint);
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(body, _serOps);
    final http.Response response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http.put(url, headers: headers, body: json, encoding: Encoding.getByName(utf8Val)).timeout(_timeout);
      checkUnauthorizedAccess(endpoint, response);
    } on SocketException {
      throw FetchDataException(noInternetConnectionError);
    } on TimeoutException {
      throw FetchDataException(requestTimeoutError);
    }
    debugPrint("END: PUT Request Method end : ${ProfileConstants.api}$endpoint");
    return response;
  }

  static Future<http.Response> patchRequest<T>(String endpoint, T body) async {
    debugPrint("BEGIN: PATCH Request Method start : ${ProfileConstants.api}$endpoint");
    if (!ProfileConstants.isProduction) return await mockRequest('PATCH', endpoint);
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(body, _serOps);
    final http.Response response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http.patch(url, headers: headers, body: json, encoding: Encoding.getByName(utf8Val)).timeout(_timeout);
      checkUnauthorizedAccess(endpoint, response);
    } on SocketException {
      throw FetchDataException(noInternetConnectionError);
    } on TimeoutException {
      throw FetchDataException(requestTimeoutError);
    }
    debugPrint("END: PATCH Request Method end : ${ProfileConstants.api}$endpoint");
    return response;
  }

  static Future<http.Response> deleteRequest(String endpoint) async {
    debugPrint("BEGIN: DELETE Request Method start : ${ProfileConstants.api}$endpoint");
    if (!ProfileConstants.isProduction) return await mockRequest('DELETE', endpoint);
    var headers = await HttpUtils.headers();
    final http.Response response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http.delete(url, headers: headers).timeout(_timeout);
      checkUnauthorizedAccess(endpoint, response);
    } on SocketException {
      throw FetchDataException(noInternetConnectionError);
    } on TimeoutException {
      throw FetchDataException(requestTimeoutError);
    }
    debugPrint("END: DELETE Request Method end : ${ProfileConstants.api}$endpoint");
    return response;
  }

  // dynamic returnResponse(http.Response response) {
  //   if (ProfileConstants.isProduction == true) {
  //     return 200;
  //   }
  //   switch (response.statusCode) {
  //     case 200:
  //       return response;
  //     case 400:
  //       throw BadRequestException(response.body.toString());
  //     case 401:
  //     case 403:
  //       throw UnauthorizedException(response.body.toString());
  //     case 417:
  //       throw ApiBusinessException(response.body.toString());
  //     case 500:
  //     default:
  //       throw FetchDataException(
  //           'Error occurred while Communication with Server with StatusCode : ${response.statusCode}');
  //   }
  // }

  static Future<http.Response> mockRequest(String httpMethod, String endpoint) async {
    debugPrint("BEGIN: Mock Request Method start : $httpMethod $endpoint");

    var headers = await HttpUtils.headers();
    if (!allowedPaths.contains(endpoint)) {
      if (headers['Authorization'] == null) {
        throw UnauthorizedException("Unauthorized Access");
      }
    }

    String responseBody = "OK";
    int httpStatusCode = HttpStatus.ok;
    Future<http.Response> response = Future.value(http.Response("", httpStatusCode));
    switch (httpMethod) {
      case 'POST':
        httpStatusCode = HttpStatus.created;
        break;
      case 'DELETE':
        httpStatusCode = HttpStatus.noContent;
        return Future.value(http.Response(responseBody, httpStatusCode));
      case 'GET':
      case 'PUT':
        httpStatusCode = HttpStatus.ok;
        break;
      default:
        httpStatusCode = HttpStatus.ok;
    }

    try {
      String path = ProfileConstants.api;
      // @formatter:off
      // use GET_resource.json for all GET requests except for id based GET requests
      final queryParams =
          endpoint
              .replaceAll("/", "_")
              .replaceAll("?", "_")
              .replaceAll("&", "_")
              .replaceAll("=", "_")
              .replaceAll(",", "_")
              .replaceAll(".", "_")
              .replaceAll(";", "_")
              .replaceAll("-", "_")
      ;
      // @formatter:on
      String fileName = "$httpMethod$queryParams.json";
      String mockDataPath = "$path/$fileName";
      debugPrint("Mock data path: $mockDataPath");
      responseBody = await rootBundle.loadString(mockDataPath);
      response = Future.value(http.Response(responseBody, httpStatusCode));
      debugPrint("Mock data loaded from $httpMethod $endpoint : response body length: ${responseBody.length}");
    } catch (e) {
      debugPrint("Error loading mock data httpMethod:$httpMethod, endpoint:$endpoint. error: $e");
    }
    debugPrint("END: Mock Request Method end : $httpMethod $endpoint");
    return response;
  }
}
