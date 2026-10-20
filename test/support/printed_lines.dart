import 'dart:async';

/// The lines that [body] prints, the lines of AppLogger among them, in the order they were printed.
///
/// The test configuration prints each AppLogger line with the label of its level, such as `[W]` for warn, so a test
/// can tell at which level a line was logged.
Future<List<String>> printedLines(FutureOr<void> Function() body) async {
  final lines = <String>[];
  await runZoned(() async => body(), zoneSpecification: ZoneSpecification(print: (_, _, _, line) => lines.add(line)));
  return lines;
}
