import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/public_endpoint.dart';

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
///
/// It answers a protected path sent without a token with 401 and rejects
/// with `callFollowingErrorInterceptor: true` for the same reason: a server
/// 401 runs every onError handler, so [TokenRefreshInterceptor] ends the
/// session when the token cannot be refreshed, and the dev console and
/// logging record the failure. A public endpoint ([isPublicEndpoint]),
/// sign-in among them, is never rejected.
///
/// A request whose mock file is missing fails with 501 Not Implemented, also
/// rejected with `callFollowingErrorInterceptor: true`, so the dev console
/// and logging record it. The error names the missing file. The mock cannot
/// answer that request, so the caller gets a failure, not a made-up success.
/// A DELETE needs no file and always gets 204.
class MockInterceptor extends Interceptor {
  MockInterceptor({this.appConfig = const AppConfig.dev()});

  final AppConfig appConfig;

  static final _log = AppLogger.getLogger('MockInterceptor');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _log.debug('Mock request: {} {}', [options.method, options.path]);

    // Simulate network latency in dev (not in tests)
    if (!appConfig.isTest) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Auth check for non-public endpoints
    final basePath = options.extra['_basePath'] as String? ?? options.path;
    if (!isPublicEndpoint(options)) {
      _log.debug('mockRequest: checking auth for endpoint: {}', [basePath]);
      if (options.headers['Authorization'] == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 401, data: 'Unauthorized Access'),
          ),
          true,
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

    final mockDataPath = 'assets/mock/$mockFileName';
    _log.debug('Mock data path: {}', [mockDataPath]);
    final String responseBody;
    try {
      responseBody = await rootBundle.loadString(mockDataPath);
    } catch (e) {
      _log.error('No mock data for {} {}: {} could not be loaded: {}', [options.method, basePath, mockDataPath, e]);
      final reason = 'No mock data for ${options.method} $basePath: $mockDataPath could not be loaded';
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: HttpStatus.notImplemented, data: reason),
          error: e,
          message: reason,
        ),
        true,
      );
      return;
    }
    _log.debug('Mock data loaded: {} {} (body length: {})', [options.method, basePath, responseBody.length]);
    handler.resolve(Response(requestOptions: options, data: responseBody, statusCode: statusCode), true);
  }
}
