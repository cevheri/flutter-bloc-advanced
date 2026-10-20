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

    // A typo in minimumVersion returned false, so the forced update was silently off. The caller decides what a
    // malformed version means and logs it.
    test('throws a FormatException naming a malformed version', () {
      expect(
        () => Semver.isBelow('not-a-version', '1.0.0'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('not-a-version'))),
      );
      expect(
        () => Semver.isBelow('1.0.0', '1.0,1'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('1.0,1'))),
      );
    });

    test('rejects what int.parse would accept but is not a version', () {
      for (final version in const [
        '',
        ' 1.0.0',
        '1.0.0 ',
        '+1.0.0',
        '1.-1.0',
        '0x1.0.0',
        '1..0',
        '1.0.0.0',
        'v1.0.0',
      ]) {
        expect(() => Semver.isBelow('1.0.0', version), throwsFormatException, reason: version);
      }
    });
  });
}
