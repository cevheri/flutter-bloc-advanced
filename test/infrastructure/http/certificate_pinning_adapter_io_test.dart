import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinning_adapter_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the HttpClient the pinned adapter builds, to capture the bad-certificate callback that dart:io
/// calls during the TLS handshake.
class _FakeHttpClient extends Fake implements HttpClient {
  bool Function(X509Certificate cert, String host, int port)? badCertificateCallback;
}

class _FakeHttpOverrides extends HttpOverrides {
  final client = _FakeHttpClient();

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

class _FakeCertificate extends Fake implements X509Certificate {
  _FakeCertificate(this.der);

  @override
  final Uint8List der;

  @override
  String get subject => '/CN=api.example.test';
}

/// A self-signed certificate and its key, made for these tests only; they protect nothing. A loopback server presents
/// them so that the pinned adapter's callback runs inside a real dart:io TLS handshake.
const _testCertificatePem = '''
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

const _testPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgqMEuR7Q80+a0o1Ss
kCpq7gX+XdcByMJwRE/icoCUZvChRANCAAT7knBZMSMXOWK9so3//ZMtwNqS3PPU
XYShe0Hn80o5i/ei0NKyadlNqQY+xN6mI1/RhhNyXCqS6fXj3zug6Zgw
-----END PRIVATE KEY-----
''';

/// flutter_test answers every HttpClient request with a 400; the TLS tests need real sockets.
class _RealHttpOverrides extends HttpOverrides {}

Uint8List _derOf(String pem) =>
    base64.decode(pem.split('\n').where((line) => line.isNotEmpty && !line.startsWith('-----')).join());

void main() {
  final pinnedDer = Uint8List.fromList([1, 2, 3, 4]);

  /// Builds the pinned adapter's HttpClient and returns the bad-certificate callback it installed.
  bool Function(X509Certificate cert, String host, int port) installedCallback() {
    final adapter = buildPinnedAdapter([CertificatePinner.computePin(pinnedDer)]) as IOHttpClientAdapter;
    final overrides = _FakeHttpOverrides();
    HttpOverrides.runWithHttpOverrides(() => adapter.createHttpClient!(), overrides);
    return overrides.client.badCertificateCallback!;
  }

  group('buildPinnedAdapter with pins', () {
    test('accepts a certificate that matches a pin', () {
      expect(installedCallback()(_FakeCertificate(pinnedDer), 'api.example.test', 443), isTrue);
    });

    // dart:io fails the handshake with the exception the callback throws, so a pin mismatch reaches dio as this
    // exception instead of a HandshakeException that cannot be told apart from other TLS failures.
    test('fails a certificate that matches no pin with CertificatePinningException', () {
      final callback = installedCallback();

      expect(
        () => callback(_FakeCertificate(Uint8List.fromList([9, 9, 9, 9])), 'api.example.test', 443),
        throwsA(
          isA<CertificatePinningException>()
              .having((e) => e.host, 'host', 'api.example.test')
              .having((e) => e.port, 'port', 443),
        ),
      );
    });
  });

  // The fix relies on dart:io failing the handshake with the very exception the callback throws, which its API does
  // not document. These tests run the callback inside a real handshake, so a dart:io or dio change that wraps or
  // replaces the exception fails here instead of letting a pin mismatch fall back to the cache again.
  group('buildPinnedAdapter over a real TLS handshake', () {
    late HttpServer server;

    setUp(() async {
      final context = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(_testCertificatePem))
        ..usePrivateKeyBytes(utf8.encode(_testPrivateKeyPem));
      server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
      server.listen(
        (request) => request.response
          ..write('ok')
          ..close(),
      );
      addTearDown(() => server.close(force: true));
    });

    Future<Response<String>> getWithPins(List<String> pins) => HttpOverrides.runWithHttpOverrides(
      () => (Dio()..httpClientAdapter = buildPinnedAdapter(pins)).get<String>('https://127.0.0.1:${server.port}/'),
      _RealHttpOverrides(),
    );

    test('completes the request when the certificate matches a pin', () async {
      final response = await getWithPins([CertificatePinner.computePin(_derOf(_testCertificatePem))]);

      expect(response.data, 'ok');
    });

    test('fails the request with CertificatePinningException when the certificate matches no pin', () async {
      await expectLater(
        getWithPins([CertificatePinner.computePin(pinnedDer)]),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.unknown)
              .having((e) => e.error, 'error', isA<CertificatePinningException>()),
        ),
      );
    });
  });
}
