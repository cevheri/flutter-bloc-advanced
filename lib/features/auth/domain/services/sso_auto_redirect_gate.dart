/// Whether the login page may still send the user to the identity provider on its own, without a tap.
///
/// The automatic redirect fires at most once per app run, and never after a sign-in error, a cancel or a user logout:
/// each of those closes the gate for the rest of the run, so no redirect loop can start. The gate starts open and
/// never opens again.
final class SsoAutoRedirectGate {
  bool _open = true;

  bool get isOpen => _open;

  void close() => _open = false;
}
