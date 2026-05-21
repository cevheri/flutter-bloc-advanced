import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_test/flutter_test.dart';

String _hashOf(Uint8List bytes) => base64.encode(sha256.convert(bytes).bytes);

void main() {
  group('CertificatePinner.matches', () {
    final certA = Uint8List.fromList([1, 2, 3, 4]);
    final certB = Uint8List.fromList([5, 6, 7, 8]);
    final pinA = _hashOf(certA);
    final pinB = _hashOf(certB);

    test('empty pin list returns false (pinning misconfigured — fail closed)', () {
      // Disabled mode is enforced at the adapter wiring level, not here.
      // If pinner is invoked with an empty list, it must reject — never
      // silently allow.
      expect(CertificatePinner.matches(certA, const []), isFalse);
    });

    test('exact pin match returns true', () {
      expect(CertificatePinner.matches(certA, [pinA]), isTrue);
    });

    test('non-matching pin returns false', () {
      expect(CertificatePinner.matches(certA, [pinB]), isFalse);
    });

    test('multiple pins, one matching returns true (backup pin scenario)', () {
      expect(CertificatePinner.matches(certA, [pinB, pinA]), isTrue);
    });

    test('multiple pins, none matching returns false', () {
      final pinC = _hashOf(Uint8List.fromList([9, 9, 9]));
      expect(CertificatePinner.matches(certA, [pinB, pinC]), isFalse);
    });

    test('pin comparison is case-sensitive (base64 is case-sensitive)', () {
      final lowercased = pinA.toLowerCase();
      // If pinA happens to be already all lowercase (rare for base64), skip.
      if (lowercased == pinA) return;
      expect(CertificatePinner.matches(certA, [lowercased]), isFalse);
    });
  });

  group('CertificatePinner.computePin', () {
    test('produces the canonical base64(sha256(cert.der)) string', () {
      final der = Uint8List.fromList(List.generate(64, (i) => i));
      final expected = base64.encode(sha256.convert(der).bytes);
      expect(CertificatePinner.computePin(der), equals(expected));
    });

    test('different cert bytes → different pins', () {
      final a = CertificatePinner.computePin(Uint8List.fromList([1, 2, 3]));
      final b = CertificatePinner.computePin(Uint8List.fromList([3, 2, 1]));
      expect(a, isNot(equals(b)));
    });
  });
}
