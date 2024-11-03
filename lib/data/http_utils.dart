import 'dart:async';
import 'dart:convert' show Encoding, json, utf8;
import 'dart:developer';
import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../configuration/environment.dart';
import '../main/main_local.dart';
import '../utils/app_constants.dart';
import 'app_api_exception.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class HttpUtils {
  static String errorHeader = 'x-${ProfileConstants.isProduction == true ? AppConstants.APP_KEY : "default_token"}App-error';
  static String successResult = 'success';
  static String keyForJWTToken = 'jwt-token';
  static String badRequestServerKey = 'error.400';
  static String errorServerKey = 'error.500';
  static const String generalNoErrorKey = 'none';
  static int timeout = 30;

  /// Default headers for all requests (can be overridden with [addCustomHttpHeader])
  static final _defaultHttpHeaders = {'Accept': 'application/json', 'Content-Type': 'application/json'};

  static final _customHttpHeaders = <String, String>{};

  /// Add custom http headers when you need to override the default ones
  static void addCustomHttpHeader(String key, String value) {
    log("add custom headers $key: $value");
    _customHttpHeaders[key] = value;
  }

  static String encodeUTF8(String toEncode) {
    return utf8.decode(toEncode.runes.toList());
  }

  static Future<Map<String, String>> headers() async {
    String? jwt = ProfileConstants.isProduction == true ? getStorageCache["jwtToken"] : "default_token";
    Map<String, String> headerParameters = <String, String>{};

    //custom http headers entries
    if (_customHttpHeaders.isNotEmpty) {
      log("custom headers");
      headerParameters.addAll(_customHttpHeaders);
      _customHttpHeaders.clear();
    } else {
      headerParameters.addAll(_defaultHttpHeaders);
      log("default headers");
    }

    if (jwt != "") {
      headerParameters['Authorization'] = 'Bearer $jwt';
    } else {
      headerParameters.remove('Authorization');
    }

    return headerParameters;
  }

  static Future<Response> postRequest<T>(String endpoint, T body, {Map<String, String>? headers}) async {
    /// if isMock is true, return mock data instead of making a request
    if (!ProfileConstants.isProduction) return await mockRequest('POST', endpoint);

    var headers = await HttpUtils.headers();
    String messageBody = "";

    if (headers['Content-Type'] == 'application/json') {
      messageBody = JsonMapper.serialize(
        body,
        SerializationOptions(
          indent: '',
          ignoreDefaultMembers: true,
          ignoreNullMembers: true,
          ignoreUnknownTypes: true,
        ),
      );
    } else {
      messageBody = body as String;
    }

    Response? response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');

      response = await http
          .post(
            url,
            headers: headers,
            body: messageBody,
            encoding: Encoding.getByName('utf-8'),
          )
          .timeout(Duration(seconds: timeout));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
    return response;
  }

  static Future<String> getRequest(String endpoint) async {
    debugPrint("GET Request Method start : ${ProfileConstants.api}$endpoint");

    /// if isMock is true, return mock data instead of making a request
    if (!ProfileConstants.isProduction) return (await mockRequest('GET', endpoint)).body.toString();

    var headers = await HttpUtils.headers();
    try {
      var response = await http.get(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers).timeout(Duration(seconds: timeout));
      if (response.statusCode == 401) {
        throw UnauthorisedException(response.body.toString());
      }
      var result = encodeUTF8(response.body.toString());
      debugPrint(" GET Request Method end : ${ProfileConstants.api}$endpoint");
      return result;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
  }

  // static Future<int> getRequestHeader(String endpoint) async {
  //   debugPrint(endpoint);
  //   var headers = await HttpUtils.headers();
  //   try {
  //     var result = await http
  //         .get(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers)
  //         .timeout(Duration(seconds: timeout));
  //     debugPrint(result.headers.toString());
  //     if (result.statusCode == 401) {
  //       throw UnauthorisedException(result.headers.toString());
  //     }
  //     Map<String, dynamic> pageable = <String, dynamic>{};
  //     pageable['x-total-count'] = result.headers['x-total-count'];
  //     int countOffers = int.parse(result.headers['x-total-count']!);
  //     return countOffers;
  //   } on SocketException {
  //     throw FetchDataException('No Internet connection');
  //   } on TimeoutException {
  //     throw FetchDataException('Request timeout');
  //   }
  // }

  static Future<Response> putRequest<T>(String endpoint, T body) async {
    if (!ProfileConstants.isProduction) return await mockRequest('PUT', endpoint);
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(
      body,
      SerializationOptions(
        indent: '',
        ignoreDefaultMembers: true,
        ignoreNullMembers: true,
        ignoreUnknownTypes: true,
      ),
    );
    Response response;
    try {
      response = await http
          .put(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers, body: json, encoding: Encoding.getByName('utf-8'))
          .timeout(Duration(seconds: timeout));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
    return response;
  }

  static Future<Response> patchRequest<T>(String endpoint, T body) async {
    if (!ProfileConstants.isProduction) return await mockRequest('PATCH', endpoint);
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(
      body,
      SerializationOptions(
        indent: '',
        ignoreDefaultMembers: true,
        ignoreNullMembers: true,
        ignoreUnknownTypes: true,
      ),
    );
    Response response;
    try {
      response = await http
          .patch(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers, body: json, encoding: Encoding.getByName('utf-8'))
          .timeout(Duration(seconds: timeout));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
    return response;
  }

  static Future<Response> deleteRequest(String endpoint) async {
    if (!ProfileConstants.isProduction) return await mockRequest('DELETE', endpoint);
    var headers = await HttpUtils.headers();
    try {
      return await http.delete(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers).timeout(Duration(seconds: timeout));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
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
  //       throw UnauthorisedException(response.body.toString());
  //     case 417:
  //       throw ApiBusinessException(response.body.toString());
  //     case 500:
  //     default:
  //       throw FetchDataException(
  //           'Error occurred while Communication with Server with StatusCode : ${response.statusCode}');
  //   }
  // }

  static Future<Response> mockRequest(String httpMethod, String endpoint) async {
    debugPrint("Mock request: $httpMethod $endpoint");
    String responseBody = "OK";
    int httpStatusCode = HttpStatus.ok;
    Future<Response> response = Future.value(Response("", httpStatusCode));
    switch (httpMethod) {
      case 'POST':
        httpStatusCode = HttpStatus.created;
        break;
      case 'DELETE':
        httpStatusCode = HttpStatus.noContent;
        return Future.value(Response(responseBody, httpStatusCode));
      case 'GET':
      case 'PUT':
      default:
        httpStatusCode = HttpStatus.ok;
    }

    try {
      String path = 'mock/';
      String fileName = "$httpMethod${endpoint.replaceAll("/", "_")}.json";
      String mockDataPath = path + fileName;
      responseBody = await rootBundle.loadString(mockDataPath);
      response = Future.value(Response(responseBody, httpStatusCode));
      debugPrint("Mock data loaded from $responseBody");
    } catch (e) {
      debugPrint("Error loading mock data httpMethod:$httpMethod, endpoint:$endpoint. error: $e");
    }

    final cacheStorage = getStorageCache;
    String username = cacheStorage["username"] ?? '';
    if (endpoint.startsWith('/account') || endpoint.startsWith('/users')) {
      try {
        var responseJson = json.decode(responseBody);
        responseJson['login'] = username;
        responseJson['authorities'] = ['ROLE_${username.toUpperCase()}'];
        response = Future.value(Response(json.encode(responseJson), httpStatusCode));
      } catch (e) {
        debugPrint("There is no response body to update with username");
      }
    }

    return response;
  }
}
