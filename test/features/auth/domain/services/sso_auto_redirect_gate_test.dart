import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SsoAutoRedirectGate', () {
    test('starts open', () {
      expect(SsoAutoRedirectGate().isOpen, isTrue);
    });

    test('is closed after close, and stays closed', () {
      final gate = SsoAutoRedirectGate()..close();
      expect(gate.isOpen, isFalse);

      gate.close();
      expect(gate.isOpen, isFalse);
    });
  });
}
