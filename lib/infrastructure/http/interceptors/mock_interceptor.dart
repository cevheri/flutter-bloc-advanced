import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/allowed_paths.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

/// Intercepts all requests in dev/test mode and returns mock JSON from assets.
///
/// Simulates the network, so it must sit **LAST** in the interceptor chain
/// (after [AuthInterceptor] for the Authorization check, and after the
/// observability interceptors). It resolves with
/// `callFollowingResponseInterceptor: true` so the mock response travels
/// back through every onResponse handler — DevConsole capture, verbose
/// logging, cache writes — exactly like a real round-trip would. Without
/// that flag the response short-circuits and those handlers never fire,
/// leaving the dev console Network tab empty in mock mode.
class MockInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('MockInterceptor');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _log.debug('Mock request: {} {}', [options.method, options.path]);

    // Simulate network latency in dev (not in tests)
    if (!ProfileConstants.isTest) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Auth check for non-public paths
    final basePath = options.extra['_basePath'] as String? ?? options.path;
    if (!allowedPaths.contains(basePath)) {
      _log.debug('mockRequest: checking auth for endpoint: {}', [basePath]);
      if (options.headers['Authorization'] == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 401, data: 'Unauthorized Access'),
          ),
        );
        return;
      }
    }

    // Early-return for DELETE (no mock file needed)
    if (options.method == 'DELETE') {
      handler.resolve(Response(requestOptions: options, data: 'OK', statusCode: HttpStatus.noContent), true);
      return;
    }

    // Determine status code
    final statusCode = options.method == 'POST' ? HttpStatus.created : HttpStatus.ok;

    // Build mock file path
    final hasPathParams = options.extra['_pathParams'] != null;
    final hasQueryParams = options.extra['_queryParams'] != null;
    final filePath = basePath.replaceAll('/', '_').replaceAll('-', '_');

    String mockFileName;
    if (hasPathParams) {
      mockFileName = '${options.method}${filePath}_pathParams.json';
    } else if (hasQueryParams) {
      mockFileName = '${options.method}${filePath}_queryParams.json';
    } else {
      mockFileName = '${options.method}$filePath.json';
    }

    try {
      final mockDataPath = 'assets/mock/$mockFileName';
      _log.debug('Mock data path: {}', [mockDataPath]);
      final responseBody = await rootBundle.loadString(mockDataPath);
      _log.debug('Mock data loaded: {} {} (body length: {})', [options.method, basePath, responseBody.length]);
      handler.resolve(Response(requestOptions: options, data: responseBody, statusCode: statusCode), true);
    } catch (e) {
      _log.error('Error loading mock data: {} {}, error: {}', [options.method, basePath, e]);
      handler.resolve(Response(requestOptions: options, data: 'OK', statusCode: statusCode), true);
    }
  }
}
