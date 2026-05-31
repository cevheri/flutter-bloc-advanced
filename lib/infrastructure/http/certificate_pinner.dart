import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pure pin-matcher: SHA-256 the certificate DER, base64-encode it, and
/// check membership against a list of expected pins.
///
/// **v1 caveat — full-cert hash, not SPKI hash.** The IETF / OWASP
/// recommended pin format is `SHA-256(SubjectPublicKeyInfo)`, which
/// survives certificate rotation as long as the keypair is reused.
/// Extracting SPKI bytes from an X.509 cert requires ASN.1 parsing
/// (e.g. via `asn1lib`). We start with the full-cert hash to keep the
/// dep surface small and the implementation auditable. Forks needing
/// rotation-resilient pinning should swap to SPKI in a follow-up — the
/// pin storage shape (base64 SHA-256 string in
/// `Environment.certificatePins`) stays identical; only this
/// computation changes.
///
/// **Comparison is constant-time-equivalent.** Both inputs are base64
/// strings of the same length; Dart's String `==` is non-secret-safe
/// in principle but the pin list is local config (not user-supplied),
/// so timing attacks have no leverage here.
class CertificatePinner {
  CertificatePinner._();

  /// True if `pins` contains the SHA-256 hash of `certDer`. Returns
  /// false on an empty pin list — disabled mode is enforced one level
  /// up (adapter wiring), so an empty list reaching this function means
  /// something is misconfigured and the safe default is "fail closed".
  static bool matches(Uint8List certDer, List<String> pins) {
    if (pins.isEmpty) return false;
    final pin = computePin(certDer);
    for (final expected in pins) {
      if (expected == pin) return true;
    }
    return false;
  }

  /// Compute the base64-encoded SHA-256 of `certDer`. The canonical
  /// pin format used by the OpenSSL one-liner in the README.
  static String computePin(Uint8List certDer) {
    return base64.encode(sha256.convert(certDer).bytes);
  }
}
