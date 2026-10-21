import 'dart:async';

// The browser-only tests skip the global bootstrap in test/flutter_test_config.dart, which imports alchemist and does
// not compile for the web.
Future<void> testExecutable(FutureOr<void> Function() testMain) async => testMain();
