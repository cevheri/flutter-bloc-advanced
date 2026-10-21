import 'dart:convert';

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

/// The longest return path kept, in UTF-8 bytes rather than characters.
const _maxReturnPathBytes = 1024;
final _controlCharacter = RegExp('[\u0000-\u001f\u007f]');

/// The return path carried through a sign-in, or null when [candidate] is not safe to send the user to afterwards.
///
/// On top of the rules of [safeRedirectTarget], it drops a path longer than 1024 UTF-8 bytes, a path holding a control
/// character, and the login route [loginPath] itself or anything under `loginPath/`, which would land the user back
/// on the sign-in page. An unsafe value is dropped, not repaired; the caller falls back to its default page.
String? safeReturnPath(String? candidate, {required String loginPath}) {
  if (candidate == null) return null;
  // An empty fallback can never be a safe path, so it marks the candidates safeRedirectTarget rejects.
  if (safeRedirectTarget(candidate, fallback: '').isEmpty) return null;
  if (utf8.encode(candidate).length > _maxReturnPathBytes) return null;
  if (_controlCharacter.hasMatch(candidate)) return null;
  final path = Uri.parse(candidate).path;
  if (path == loginPath || path.startsWith('$loginPath/')) return null;
  return candidate;
}
