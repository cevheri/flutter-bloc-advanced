import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';

/// IO (mobile/desktop) build of [buildPinnedAdapter].
///
/// - **Empty pins** → default adapter (`IOHttpClientAdapter` with system
///   trust). Pinning is disabled; behaviour matches today.
/// - **Non-empty pins** → custom adapter that builds `HttpClient` instances
///   with `SecurityContext(withTrustedRoots: false)` so **every** certificate
///   falls through `badCertificateCallback` (the only way to enforce pinning
///   even against system-trusted but adversarial CAs — e.g. a corporate MITM
///   proxy or malware-installed root). The callback returns true only when the
///   live cert matches one of the configured pins; otherwise it throws a
///   [CertificatePinningException] and the TLS handshake fails with that
///   exception, which Dio reports as the `error` of a
///   `DioExceptionType.unknown`, not `badCertificate` (Dio raises that only
///   for `IOHttpClientAdapter.validateCertificate`). `ResilienceInterceptor`
///   does not retry `unknown` errors, and `CacheInterceptor` never answers a
///   pin mismatch from cache.
HttpClientAdapter buildPinnedAdapter(List<String> pins) {
  if (pins.isEmpty) {
    return IOHttpClientAdapter();
  }
  return IOHttpClientAdapter()
    ..createHttpClient = () {
      final ctx = SecurityContext(withTrustedRoots: false);
      final client = HttpClient(context: ctx);
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final accepted = CertificatePinner.matches(cert.der, pins);
        if (!accepted) {
          AppLogger.getLogger('CertificatePinningAdapter')
              .warn('Pin mismatch — rejecting connection to {}:{} (subject={})', [host, port, cert.subject]);
          // Thrown instead of returning false: dart:io fails the handshake with this exception, so the layers above
          // can tell a pin mismatch from a network failure. Returning false would surface as a HandshakeException.
          throw CertificatePinningException(host, port);
        }
        return accepted;
      };
      return client;
    };
}
