import 'package:dio/dio.dart';

/// An API endpoint, by HTTP method and by the path the `ApiClient` method is called with, before any path parameters.
typedef PublicEndpoint = ({String method, String path});

/// The API endpoints that serve requests without a session: sign-in, the OTP sign-in, registration, password reset,
/// the token refresh, and the app config.
///
/// The lifecycle checks read the app config when the app starts and when it comes back to the foreground, so before
/// sign-in as well.
///
/// `AuthInterceptor` sends no token to them, `TokenRefreshInterceptor` passes a 401 from them on without a refresh (a
/// 401 from the refresh endpoint still ends the session), and `MockInterceptor` answers them without a token. Any other
/// method on the same path is not public. The app's own routes are not API endpoints and do not belong here.
const publicEndpoints = <PublicEndpoint>{
  (method: 'POST', path: '/authenticate'),
  (method: 'POST', path: '/authenticate/send-otp'),
  (method: 'POST', path: '/authenticate/verify-otp'),
  (method: 'POST', path: '/register'),
  (method: 'POST', path: '/account/reset-password/init'),
  (method: 'POST', path: '/api/token/refresh'),
  (method: 'GET', path: '/app/config'),
};

/// Whether [options] targets one of the [publicEndpoints].
bool isPublicEndpoint(RequestOptions options) =>
    publicEndpoints.contains((method: options.method, path: options.extra['_basePath'] as String? ?? options.path));
