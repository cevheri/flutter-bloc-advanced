import 'dart:async';
import 'dart:convert' show Encoding, utf8;
import 'dart:developer';
import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../configuration/environment.dart';
import 'app_api_exception.dart';

class HttpUtils {
  static String errorHeader = 'x-taskManagementApp-error';
  static String successResult = 'success';
  static String keyForJWTToken = 'jwt-token';
  static String badRequestServerKey = 'error.400';
  static String errorServerKey = 'error.500';
  static const String generalNoErrorKey = 'none';
  static int timeout = 5;

  static String encodeUTF8(String toEncode) {
    return utf8.decode(toEncode.runes.toList());
  }

  static Future<Map<String, String>> headers() async {
    FlutterSecureStorage storage = new FlutterSecureStorage();
    String? jwt = await storage.read(key: HttpUtils.keyForJWTToken);
    if (jwt != null) {
      return {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $jwt'};
    } else {
      return {'Accept': 'application/json', 'Content-Type': 'application/json'};
    }
  }

  static Future<Response> postRequest<T>(String endpoint, T body) async {
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(body, SerializationOptions(indent: ''));
    Response? response;
    try {
      final url = Uri.parse('${ProfileConstants.api}$endpoint');
      response = await http
          .post(
            url,
            headers: headers,
            body: json,
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

  static Future<Response> getRequest(String endpoint) async {
    var headers = await HttpUtils.headers();
    log('GET REQUEST: ${ProfileConstants.api}$endpoint');
    try {
      var result = await http.get(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers).timeout(Duration(seconds: timeout));
      if(result.statusCode == 401) {
        throw UnauthorisedException(result.body.toString());
      }
      return result;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
  }

  static Future<Response> putRequest<T>(String endpoint, T body) async {
    var headers = await HttpUtils.headers();
    final String json = JsonMapper.serialize(body, SerializationOptions(indent: ''));
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

  static Future<Response> deleteRequest(String endpoint) async {
    var headers = await HttpUtils.headers();
    try {
      return await http.delete(Uri.parse('${ProfileConstants.api}$endpoint'), headers: headers).timeout(Duration(seconds: timeout));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return response;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 417:
        throw ApiBusinessException(
            response.body.toString()); //TODO cevheri: handle http.417 exception and throw ApiBusinessException with translated error messages
      case 500:
      default:
        throw FetchDataException('Error occured while Communication with Server with StatusCode : ${response.statusCode}');
    }
  }
}
