@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `tool/generate_feature.dart` against drifting from the code it generates for.
///
/// The generator writes Dart from string templates, so nothing compiles its output until someone runs it. It went
/// stale unnoticed once: its repository called `ApiClient.get` statically after `ApiClient` became an injected
/// instance, and it wrote the list mock as `GET_<feature>.json` while `MockInterceptor` requests
/// `GET_<feature>_queryParams.json` for a call with query parameters.
///
/// This test generates a feature into a temporary copy of the project and runs on the result what CI runs on a
/// commit: the format check, the analyzer and the tests. The generated repository and route tests send their
/// requests through the real `ApiClient` and `MockInterceptor`, so they fail when a generated mock file is not the
/// one `MockInterceptor` looks up for the request.
void main() {
  late Directory project;

  setUpAll(() async {
    project = await Directory.systemTemp.createTemp('feature_generator_test_');
    _copyProject(project);
    await _run(project, _dart, ['run', 'tool/generate_feature.dart', _feature]);
  });

  tearDownAll(() => project.delete(recursive: true));

  test('the generated code is formatted', () async {
    await _run(project, _dart, [
      'format',
      '--line-length=120',
      '--output=none',
      '--set-exit-if-changed',
      ..._generated,
    ]);
  });

  test('the generated code analyzes cleanly', () async {
    await _run(project, _dart, ['analyze', '--fatal-infos', ..._generated]);
  });

  test('the generated tests pass', () async {
    await _run(project, _flutter, ['test', '--no-pub', '--reporter=failures-only', 'test/features/$_feature']);
  });
}

/// Two words, so that the snake, kebab and camel case forms of the name differ.
const _feature = 'purchase_orders';

const _generated = ['lib/features/$_feature', 'test/features/$_feature'];

String get _flutterRoot {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set. Run this test with flutter test.');
  return root;
}

String get _dart => '$_flutterRoot/bin/dart${Platform.isWindows ? '.bat' : ''}';

String get _flutter => '$_flutterRoot/bin/flutter${Platform.isWindows ? '.bat' : ''}';

/// Copies what generating, analyzing and testing a feature needs: the package with its resolved dependencies, the
/// generator, the assets and the test bootstrap. The platform folders and the other tests stay behind.
void _copyProject(Directory target) {
  const files = [
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
    '.dart_tool/package_config.json',
    '.dart_tool/package_graph.json',
    'test/flutter_test_config.dart',
  ];
  const directories = ['lib', 'assets', 'tool', 'test/support', 'test/mocks'];

  for (final path in files) {
    final copy = File('${target.path}/$path');
    copy.parent.createSync(recursive: true);
    File(path).copySync(copy.path);
  }
  for (final path in directories) {
    for (final file in Directory(path).listSync(recursive: true).whereType<File>()) {
      final copy = File('${target.path}/${file.path}');
      copy.parent.createSync(recursive: true);
      file.copySync(copy.path);
    }
  }
}

Future<void> _run(Directory project, String executable, List<String> arguments) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: project.path,
    runInShell: Platform.isWindows,
  );
  expect(
    result.exitCode,
    0,
    reason: '`${arguments.join(' ')}` failed in ${project.path}:\n${result.stdout}\n${result.stderr}',
  );
}
