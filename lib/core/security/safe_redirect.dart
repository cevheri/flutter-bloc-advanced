/// Open-redirect guard. Returns [candidate] only if it is a safe local
/// path; falls back to [fallback] for any input that could redirect
/// the user off-origin after login — absolute URLs (`https://evil.com`),
/// protocol-relative paths (`//evil.com`), backslash games
/// (`/\evil.com` which some browsers interpret as scheme-relative),
/// or non-URL inputs.
///
/// Tightly conservative on purpose. Any case the parser is unsure
/// about is treated as unsafe and routes back to [fallback].
///
/// Lives in `core/security/` (not `app/router/`) because `features/`
/// guards consume it too and the architecture rule forbids
/// features → app imports.
String safeRedirectTarget(String? candidate, {required String fallback}) {
  if (candidate == null || candidate.isEmpty) return fallback;
  if (!candidate.startsWith('/')) return fallback;
  if (candidate.startsWith('//') || candidate.startsWith(r'/\')) return fallback;
  try {
    final parsed = Uri.parse(candidate);
    // `Uri.parse('/foo')` has empty host + no scheme. Anything else
    // is an off-origin URL or a malformed input we don't want to
    // route to.
    if (parsed.hasScheme || parsed.host.isNotEmpty) return fallback;
  } catch (_) {
    return fallback;
  }
  return candidate;
}
