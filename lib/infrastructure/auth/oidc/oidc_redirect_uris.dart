import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/security/safe_redirect.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';

/// The platform families that sign in differently: a custom scheme on Android, iOS and macOS, the same tab on web,
/// and a loopback listener on Linux and Windows.
enum OidcPlatformKind {
  android,
  ios,
  macos,
  web,
  linux,
  windows;

  /// The platform this build runs on. Throws [UnsupportedError] on Fuchsia, which the oidc package does not support.
  static OidcPlatformKind current() {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      TargetPlatform.linux => linux,
      TargetPlatform.windows => windows,
      TargetPlatform.fuchsia => throw UnsupportedError('OIDC sign-in does not support Fuchsia'),
    };
  }
}

/// The redirect URI of a sign-in and the post-logout redirect URI that an `oidc` build registers with the provider.
final class OidcRedirectUris {
  const OidcRedirectUris({required this.signIn, required this.postLogout});

  static const _nativeRedirectPath = '/oauth2redirect';
  static const _loopbackLogoutPath = '/logout';
  static const _loopbackHost = '127.0.0.1';
  static const _webRedirectPage = 'redirect.html';

  final Uri signIn;
  final Uri postLogout;

  /// The URIs of [platform]:
  /// - Android, iOS and macOS: `<redirectScheme>:/oauth2redirect` for both;
  /// - web: `<origin><base path>redirect.html` and `<origin><base path>`, taken from [pageUri], the page the app runs
  ///   in, which web requires;
  /// - Linux and Windows: `http://127.0.0.1:<loopbackPort>/oauth2redirect` and `.../logout`, where port 0 lets the
  ///   listener take any free port.
  static OidcRedirectUris forPlatform(OidcSettings settings, {required OidcPlatformKind platform, Uri? pageUri}) {
    switch (platform) {
      case OidcPlatformKind.android || OidcPlatformKind.ios || OidcPlatformKind.macos:
        final uri = Uri(scheme: settings.redirectScheme, path: _nativeRedirectPath);
        return OidcRedirectUris(signIn: uri, postLogout: uri);
      case OidcPlatformKind.web:
        if (pageUri == null) throw ArgumentError.notNull('pageUri');
        final appRoot = _webAppRoot(pageUri);
        return OidcRedirectUris(signIn: appRoot.resolve(_webRedirectPage), postLogout: appRoot);
      case OidcPlatformKind.linux || OidcPlatformKind.windows:
        Uri loopback(String path) => Uri(scheme: 'http', host: _loopbackHost, port: settings.loopbackPort, path: path);
        return OidcRedirectUris(signIn: loopback(_nativeRedirectPath), postLogout: loopback(_loopbackLogoutPath));
    }
  }
}

/// The URI a web sign-in returns the tab to: `<origin><base path>#<path>`, where the path is [returnPath] when
/// [safeReturnPath] keeps it, and `/` otherwise.
///
/// The return path travels only as the fragment, which the app's hash router starts from after the reload. The query
/// of [pageUri], which may hold an authorization `code` and `state`, is never carried over.
Uri webAppEntryUri(Uri pageUri, {String? returnPath, required String loginPath}) =>
    _webAppRoot(pageUri).replace(fragment: safeReturnPath(returnPath, loginPath: loginPath) ?? '/');

/// The origin and base path of [pageUri], with no query and no fragment. With the hash router the page path is the
/// base path the app is served under; a trailing file name such as `index.html` is dropped.
Uri _webAppRoot(Uri pageUri) {
  final path = pageUri.path;
  final basePath = path.substring(0, path.lastIndexOf('/') + 1);
  return Uri(
    scheme: pageUri.scheme,
    host: pageUri.host,
    port: pageUri.hasPort ? pageUri.port : null,
    path: basePath.isEmpty ? '/' : basePath,
  );
}
