import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

/// A self-signed certificate for 127.0.0.1 and its key, made for tests only; they protect nothing. No device trusts
/// it, so a client on system trust fails the TLS handshake with it as it does with an expired or self-signed server
/// certificate, an intercepting proxy or a captive portal.
const loopbackCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIBhTCCASugAwIBAgIUOWQcRYYdSodRYUZ7jqn+pFTihh4wCgYIKoZIzj0EAwIw
HzEdMBsGA1UEAwwUcGlubmluZy10ZXN0LmludmFsaWQwIBcNMjYxMDIwMTMxOTA2
WhgPMjEyNjA5MjYxMzE5MDZaMB8xHTAbBgNVBAMMFHBpbm5pbmctdGVzdC5pbnZh
bGlkMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+5JwWTEjFzlivbKN//2TLcDa
ktzz1F2EoXtB5/NKOYv3otDSsmnZTakGPsTepiNf0YYTclwqkun14987oOmYMKND
MEEwHQYDVR0OBBYEFJiCD9CbdhQIh+qtbyPvmiKhDTPNMA8GA1UdEwEB/wQFMAMB
Af8wDwYDVR0RBAgwBocEfwAAATAKBggqhkjOPQQDAgNIADBFAiAXqRKitoVT/hRB
Mqmqh0Hg3K5gcTJq7u0dNDpb9q16oAIhAMQQEPJ1bG+NltUGDn8PKUScDbWZ5H3r
pZm7jeCoArXY
-----END CERTIFICATE-----
''';

const _loopbackPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgqMEuR7Q80+a0o1Ss
kCpq7gX+XdcByMJwRE/icoCUZvChRANCAAT7knBZMSMXOWK9so3//ZMtwNqS3PPU
XYShe0Hn80o5i/ei0NKyadlNqQY+xN6mI1/RhhNyXCqS6fXj3zug6Zgw
-----END PRIVATE KEY-----
''';

/// The DER bytes of [loopbackCertificatePem], which a certificate pin is computed from.
Uint8List get loopbackCertificateDer => base64.decode(
  loopbackCertificatePem.split('\n').where((line) => line.isNotEmpty && !line.startsWith('-----')).join(),
);

/// The server side of a TLS handshake that presents [loopbackCertificatePem].
SecurityContext loopbackServerContext() => SecurityContext()
  ..useCertificateChainBytes(utf8.encode(loopbackCertificatePem))
  ..usePrivateKeyBytes(utf8.encode(_loopbackPrivateKeyPem));

/// Starts an HTTPS server on 127.0.0.1 that presents [loopbackCertificatePem] and answers every request with
/// [body], and closes it when the test ends.
Future<HttpServer> startLoopbackTlsServer({String body = 'ok'}) async {
  final server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, loopbackServerContext());
  addTearDown(() => server.close(force: true));
  server.listen(
    (request) => request.response
      ..write(body)
      ..close(),
  );
  return server;
}

/// A dart:io adapter that trusts [loopbackCertificatePem] alone, as a device that had the certificate installed
/// would.
HttpClientAdapter loopbackTrustingAdapter() => IOHttpClientAdapter(
  createHttpClient: () => HttpClient(
    context: SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(loopbackCertificatePem)),
  ),
);

/// Runs [body] with real sockets: flutter_test answers every HttpClient request with a 400.
Future<T> withRealSockets<T>(Future<T> Function() body) =>
    HttpOverrides.runWithHttpOverrides(body, _RealHttpOverrides());

class _RealHttpOverrides extends HttpOverrides {}
