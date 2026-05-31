/// Platform-dispatching entry point for the certificate-pinning Dio adapter.
///
/// Importers (e.g. `ApiClient`) get the IO implementation on mobile/desktop and
/// a no-op browser implementation on web — both expose the same
/// `HttpClientAdapter buildPinnedAdapter(List<String> pins)` signature.
///
/// The conditional export defaults to the web stub and selects the `dart:io`
/// implementation only when `dart:io` is available, so web builds (JS and WASM)
/// never attempt to compile `dart:io` / `dio/io.dart`. A `kIsWeb` runtime guard
/// alone is insufficient because the import itself must compile on web.
library;

export 'certificate_pinning_adapter_web.dart' if (dart.library.io) 'certificate_pinning_adapter_io.dart';
