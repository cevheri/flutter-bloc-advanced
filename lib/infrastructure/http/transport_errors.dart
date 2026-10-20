/// Recognizes the dart:io error behind a failed request.
///
/// dio reports an error it does not map itself as a `DioExceptionType.unknown` whose `error` is the original
/// exception. Telling those apart needs their dart:io types, which web builds cannot import, so this library imports
/// the `dart:io` implementation only when `dart:io` is available and a web implementation otherwise, both with the
/// same signatures, as `certificate_pinning_adapter.dart` does. Web builds (JS and WASM) never compile `dart:io`.
library;

import 'transport_errors_web.dart' if (dart.library.io) 'transport_errors_io.dart' as platform;

/// Whether [error], the `error` of a `DioException`, means that the connection was closed or reset before the whole
/// response arrived, or that dart:io could not parse the response.
///
/// dio reports a connection that cannot be opened as a connection error or a connection timeout, and one closed before
/// the response header arrived as a connection error. It reports every other cut as an unknown error with the dart:io
/// error, which is one of:
/// - an `HttpException`, when the connection is closed or reset while the response is awaited or its body is read,
///   such as "Connection reset by peer" or "Connection closed while receiving data". dart:io reports any socket or TLS
///   error of an open connection this way: over HTTPS, one whose handshake completed and verified the certificate.
///   It reports a response it cannot parse as an `HttpException` too, such as "Invalid response line" from a server
///   that does not answer in HTTP, and that counts as well. A `RedirectException` does not count: the server answered
///   with a redirect loop or with more redirects than are followed.
/// - an `OSError`, when the connection is reset as soon as it is accepted, before the request or the TLS handshake.
/// - a `SocketException`, when the connection is reset while the request is written.
///
/// A TLS failure is never a cut: dart:io reports it as a `TlsException`, such as the `HandshakeException` of an
/// untrusted certificate. That includes "Connection terminated during handshake", a handshake the server or anything
/// between it and the device closed before it completed. A dropped network can close a handshake that way too, but so
/// can a middlebox, so it fails closed like any other TLS failure. A handshake reset instead of closed is not a TLS
/// failure: dio reports it as a connection error, like a connection that cannot be opened.
///
/// Always false on web: the browser reports every failure to reach the server as an XMLHttpRequest error, which dio
/// turns into a connection error without an error object. That includes a TLS failure, so on web an untrusted or
/// expired certificate cannot be told apart from a lost connection.
bool isLostConnection(Object? error) => platform.isLostConnection(error);
