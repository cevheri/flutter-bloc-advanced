/// The app role an OpenID Connect account is mapped to.
enum OidcRole { admin, user }

/// Maps the ID token [claims] to an [OidcRole], or to null when the account holds no allowed role.
///
/// A port of LibreDB Studio's `mapOIDCRole` (`src/lib/oidc.ts`), extended in two ways:
/// - a top-level claim named exactly [roleClaim] is used as is, dots and all (`https://example.com/roles`), before
///   [roleClaim] is walked as a dot path (`realm_access.roles`);
/// - an object value contributes its keys, as does an object element of an array, which is Zitadel's role shape
///   (`{"admin": {"<org id>": "<org domain>"}}`).
///
/// Any case-insensitive match with [adminRoles] gives [OidcRole.admin], so admin wins when the claim holds both.
/// Otherwise a match with [userRoles] gives [OidcRole.user]. An account that matches neither, or whose claim is missing
/// or unreachable, is a user while [userRoles] is empty and is refused (null) once it is set.
OidcRole? mapOidcRole(
  Map<String, Object?> claims, {
  required String? roleClaim,
  required List<String> adminRoles,
  required List<String> userRoles,
}) {
  final unmatched = userRoles.isEmpty ? OidcRole.user : null;
  if (roleClaim == null || roleClaim.isEmpty) return unmatched;

  final value = claims.containsKey(roleClaim) ? claims[roleClaim] : _walkDotPath(claims, roleClaim);
  if (value == null) return unmatched;

  final values = _roleNames(value).map((v) => v.toLowerCase()).toList();
  bool matchesAny(List<String> roles) => roles.any((role) => values.contains(role.toLowerCase()));

  if (matchesAny(adminRoles)) return OidcRole.admin;
  return matchesAny(userRoles) ? OidcRole.user : unmatched;
}

/// The app roles an [OidcRole] grants.
List<String> appRolesFor(OidcRole role) => switch (role) {
  OidcRole.admin => const ['ROLE_ADMIN', 'ROLE_USER'],
  OidcRole.user => const ['ROLE_USER'],
};

/// The value at the dot [path] in [claims], or null when a step is missing or goes through a value that is not an
/// object.
Object? _walkDotPath(Map<String, Object?> claims, String path) {
  Object? value = claims;
  for (final part in path.split('.')) {
    if (value is! Map) return null;
    value = value[part];
  }
  return value;
}

List<String> _roleNames(Object value) => switch (value) {
  Map() => [for (final key in value.keys) '$key'],
  List() => [
    for (final element in value)
      if (element is Map) ...[for (final key in element.keys) '$key'] else '$element',
  ],
  _ => ['$value'],
};
