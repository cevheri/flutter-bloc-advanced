import 'package:dio/dio.dart';

/// The slot of [RequestOptions.extra] where `ApiClient` keeps the body keys
/// that its caller names as sensitive: keys whose values are secrets though
/// their names hold no credential word, such as the key a server-driven
/// form gives its password field.
const String sensitiveKeysExtra = '_sensitiveKeys';

/// The body keys that the caller of [options] named as sensitive, or none.
/// The dev console, the verbose log and the text of an HTTP error mask their
/// values along with the ones `sensitive_data_scrubber.dart` finds by name.
Set<String> sensitiveKeysOf(RequestOptions options) => options.extra[sensitiveKeysExtra] as Set<String>? ?? const {};
