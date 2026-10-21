import 'package:dio/dio.dart';

/// Whether [options] goes to the origin (scheme, host and port) of the API, the base URL `ApiClient` gives Dio.
///
/// Dio sends a request whose path is an absolute URL there instead of to the base URL, so a path a server supplies,
/// such as the submit endpoint of a dynamic form, can name any host. `AuthInterceptor` attaches the token only to a
/// request this answers true for, and `TokenRefreshInterceptor` refreshes and sends again only such a request.
///
/// A request that resolves to no host at all, a relative path with an empty base URL, goes to the API: in the dev and
/// test environments the base URL is empty and `MockInterceptor` answers these paths. With an empty base URL a request
/// to any host goes to no API origin.
bool isApiOriginRequest(RequestOptions options) {
  final target = options.uri;
  if (!target.hasScheme && !target.hasAuthority) return true;
  final api = Uri.tryParse(options.baseUrl);
  if (api == null || !api.hasScheme || api.host.isEmpty) return false;
  return target.scheme == api.scheme && target.host == api.host && target.port == api.port;
}
