import 'package:flutter_bloc_advance/shared/utils/semver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Semver.isBelow', () {
    test('major version below', () {
      expect(Semver.isBelow('1.0.0', '2.0.0'), isTrue);
    });

    test('major version above', () {
      expect(Semver.isBelow('2.0.0', '1.9.9'), isFalse);
    });

    test('minor version below', () {
      expect(Semver.isBelow('1.0.0', '1.1.0'), isTrue);
    });

    test('patch version below', () {
      expect(Semver.isBelow('1.0.0', '1.0.1'), isTrue);
    });

    test('equal versions are not below', () {
      expect(Semver.isBelow('1.2.3', '1.2.3'), isFalse);
    });

    test('missing trailing components are treated as 0', () {
      expect(Semver.isBelow('1', '1.0.0'), isFalse);
      expect(Semver.isBelow('1', '1.0.1'), isTrue);
    });

    test('returns false on parse error (caller-friendly fallback)', () {
      expect(Semver.isBelow('not-a-version', '1.0.0'), isFalse);
      expect(Semver.isBelow('1.0.0', 'x'), isFalse);
    });
  });
}
