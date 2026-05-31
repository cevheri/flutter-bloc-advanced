import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web build of [buildPinnedAdapter].
///
/// Browsers own TLS validation and JavaScript cannot intercept the handshake,
/// so certificate pinning is a hard no-op here: we return the default browser
/// adapter regardless of [pins]. Forks that need transport integrity on web
/// should rely on HTTP-layer signals (HSTS, Certificate Transparency) instead.
///
/// This file deliberately avoids `dart:io` so web (JS and WASM) builds compile.
HttpClientAdapter buildPinnedAdapter(List<String> pins) => BrowserHttpClientAdapter();
