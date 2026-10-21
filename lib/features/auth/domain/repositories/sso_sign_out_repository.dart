import 'package:flutter_bloc_advance/core/result/result.dart';

/// A logout the user starts in an `oidc` build: it clears the session on this device, then ends the session at the
/// identity provider.
abstract interface class ISsoSignOutRepository {
  /// Clears the session on this device and answers as soon as that has returned, with the provider logout started.
  ///
  /// The provider logout can take long: on Linux and Windows it waits for the browser until its flow times out, and
  /// on every platform for as long as the provider does not answer. So the app signs out on [SsoSignOut.cleared]
  /// instead of waiting for [SsoSignOut.providerLogout].
  Future<SsoSignOut> signOut();
}

/// The two steps of [ISsoSignOutRepository.signOut].
final class SsoSignOut {
  const SsoSignOut({required this.cleared, required this.providerLogout});

  /// The answer of the local logout, a failure when not all of the stored session could be removed.
  final Result<void> cleared;

  /// Completes when the provider logout has ended: with a failure when the session at the identity provider may still
  /// be active.
  final Future<Result<void>> providerLogout;
}
