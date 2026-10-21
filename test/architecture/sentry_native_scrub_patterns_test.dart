import 'dart:io';

import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/native_sentry_start.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_scrub.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Kotlin copy of the scrub policy that the Android host masks native Sentry events and breadcrumbs with.
///
/// `NativeScrubPatterns.kt` holds each pattern in a raw string, which Kotlin reads without escape processing, so its
/// text must equal the Dart pattern byte for byte; the sets and the masks must equal the Dart ones too. A Kotlin raw
/// string still reads `$` as a template, so no pattern may contain one.
///
/// The patterns must also mean the same thing on the device. Android's `java.util.regex` is backed by ICU, which reads
/// `\w`, `\d` and `\b` as Unicode classes and lets `.` skip U+0085, while Dart and the OpenJDK of the JVM unit tests
/// read them as ASCII, so the patterns spell out explicit classes instead. `\s` is left: Dart and ICU read it as
/// Unicode whitespace and OpenJDK as ASCII, so a no-break space can differ in a JVM unit test but not on a device.
///
/// The logic is held equal by `test/fixtures/native_scrub_cases.json`, which the Dart scrubber test and
/// `NativeSentryScrubberTest.kt` both run.
void main() {
  const patternsPath = 'android/app/src/main/kotlin/com/cevheri/flutter/flutter_bloc_advance/NativeScrubPatterns.kt';
  const scrubberPath = 'android/app/src/main/kotlin/com/cevheri/flutter/flutter_bloc_advance/NativeSentryScrubber.kt';

  final dartPatterns = {
    'JWT_PATTERN': jwtPattern,
    'EMAIL_PATTERN': emailPattern,
    'JSON_MEMBER_PATTERN': jsonMemberPattern,
    'NAMED_VALUE_PATTERN': namedValuePattern,
    'BEARER_PATTERN': bearerPattern,
  };
  final dartSets = {
    'SENSITIVE_HEADER_NAMES': sensitiveHeaderNames,
    'SENSITIVE_BODY_KEY_SUBSTRINGS': sensitiveBodyKeySubstrings,
    'SENSITIVE_EXACT_KEYS': sensitiveExactKeys,
    'NAVIGATION_TYPES': sentryNavigationTypes,
  };
  const dartMasks = {'SECRET_MASK': secretMask, 'JWT_MASK': jwtMask, 'EMAIL_MASK': emailMask};

  /// Every difference between the constants of [kotlinSource] and the Dart policy.
  List<String> mismatches(String kotlinSource) {
    final raw = {
      for (final match in RegExp(r'^\s*const val ([A-Z_]+) = """(.*)"""\s*$', multiLine: true).allMatches(kotlinSource))
        match[1]!: match[2]!,
    };
    final plain = {
      for (final match in RegExp(r'^\s*const val ([A-Z_]+) = "([^"]*)"\s*$', multiLine: true).allMatches(kotlinSource))
        match[1]!: match[2]!,
    };
    final problems = <String>[];
    final expectedNames = {...dartPatterns.keys, ...dartSets.keys, ...dartMasks.keys};
    final extra = {...raw.keys, ...plain.keys}.difference(expectedNames);
    if (extra.isNotEmpty) problems.add('constants without a Dart counterpart: $extra');
    for (final MapEntry(key: name, value: pattern) in dartPatterns.entries) {
      final kotlin = raw[name];
      if (kotlin == null) {
        problems.add('$name is missing or not a raw string');
      } else if (kotlin != pattern.pattern) {
        problems.add('$name differs:\n  Kotlin: $kotlin\n  Dart:   ${pattern.pattern}');
      }
      if (kotlin != null && kotlin.contains(r'$')) {
        problems.add('$name contains a \$, which Kotlin reads as a template');
      }
    }
    for (final MapEntry(key: name, value: values) in dartSets.entries) {
      final kotlin = plain[name];
      if (kotlin == null) {
        problems.add('$name is missing');
      } else if (!_sameSet(kotlin.split(','), values)) {
        problems.add('$name differs: Kotlin {$kotlin}, Dart $values');
      }
    }
    for (final MapEntry(key: name, value: mask) in dartMasks.entries) {
      if (plain[name] != mask) problems.add('$name differs: Kotlin ${plain[name]}, Dart $mask');
    }
    return problems;
  }

  test('the Kotlin patterns, sets and masks equal the Dart ones', () {
    final source = File(patternsPath).readAsStringSync();

    final problems = mismatches(source);

    expect(problems, isEmpty, reason: '$patternsPath no longer matches the Dart policy:\n${problems.join('\n')}');
  });

  // Proves on every run that the comparison above would catch a changed native pattern string.
  test('a changed Kotlin pattern string is reported', () {
    final source = File(patternsPath).readAsStringSync();
    final changed = source.replaceFirst('[A-Za-z0-9_-]{4,}', '[A-Za-z0-9_-]{5,}');

    expect(changed, isNot(source));
    expect(mismatches(changed), [contains('JWT_PATTERN differs')]);
  });

  test('the Kotlin scrubber compiles the patterns with the flags of the Dart ones', () {
    final scrubber = File(scrubberPath).readAsStringSync();

    for (final MapEntry(key: name, value: pattern) in dartPatterns.entries) {
      expect(pattern.isMultiLine || pattern.isUnicode || pattern.isDotAll, isFalse, reason: '$name has a flag');
      final compiled = pattern.isCaseSensitive
          ? 'Regex(NativeScrubPatterns.$name)'
          : 'Regex(NativeScrubPatterns.$name, RegexOption.IGNORE_CASE)';
      expect(scrubber, contains(compiled), reason: '$scrubberPath must compile $name as $compiled');
    }
  });

  test('the shared patterns use no class that ICU reads differently from Dart', () {
    final offenders = [
      for (final MapEntry(key: name, value: pattern) in dartPatterns.entries)
        if (_nonPortable(pattern.pattern) case final construct?) '$name uses $construct',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // The host starts sentry-android only when the Flutter target is this file, and on Android every Dart event leaves
  // through the native SDK, so the Gradle gate must name the entry point that selects the prod environment, in which
  // AppConfig.sentryDsn starts the Dart SDK. nativeSdkReady fails loudly at start when the two still disagree.
  test('the Gradle gate of the native SDK names the only entry point that selects the prod environment', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final gate = RegExp(r'\.name == "([^"]+)"').allMatches(gradle).map((match) => match[1]).toList();
    final prodEntryPoints = Directory('lib/main')
        .listSync()
        .whereType<File>()
        .where((file) => file.readAsStringSync().contains('Environment.prod'))
        .map((file) => file.uri.pathSegments.last)
        .toList();

    expect(gate, hasLength(1), reason: 'android/app/build.gradle.kts must compare the target file name once');
    expect(prodEntryPoints, [gate.single]);
  });

  test('MainActivity answers on the channel that nativeSdkReady asks', () {
    final activity = File('android/app/src/main/kotlin/com/cevheri/flutter/flutter_bloc_advance/MainActivity.kt')
        .readAsStringSync();

    expect(activity, contains('"$nativeSentryChannelName"'));
    expect(activity, contains('"isEnabled" -> result.success(Sentry.isEnabled())'));
  });
}

bool _sameSet(List<String> kotlin, Set<String> dart) =>
    kotlin.length == dart.length && kotlin.toSet().containsAll(dart);

/// The first construct in [pattern] that ICU reads differently from Dart: `\w`, `\d`, `\b`, or a `.` that is neither
/// escaped nor inside a character class.
String? _nonPortable(String pattern) {
  var inClass = false;
  for (var i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    if (char == r'\') {
      if (i + 1 < pattern.length && 'wWdDbB'.contains(pattern[i + 1])) return '\\${pattern[i + 1]}';
      i++;
    } else if (char == '[') {
      inClass = true;
    } else if (char == ']') {
      inClass = false;
    } else if (char == '.' && !inClass) {
      return 'a bare .';
    }
  }
  return null;
}
