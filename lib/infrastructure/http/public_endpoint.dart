import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/security/allowed_paths.dart';

/// Whether [options] targets a public endpoint: one in [allowedPaths], such
/// as sign-in, OTP, registration or password reset, which serves requests
/// without a session.
///
/// Matches the path the `ApiClient` method was called with, before any path
/// parameters, the same way `MockInterceptor` decides which requests need a
/// token.
bool isPublicEndpoint(RequestOptions options) =>
    allowedPaths.contains(options.extra['_basePath'] as String? ?? options.path);
