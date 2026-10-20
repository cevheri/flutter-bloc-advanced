/// The role of an administrator.
const String adminRole = 'ROLE_ADMIN';

/// The role of a user who is not an administrator.
const String userRole = 'ROLE_USER';

/// The role the users pages show for a user with [authorities]: [adminRole] when the user has it, otherwise the
/// first role. A user can have several roles, which the server lists in no fixed order, so the role shown is chosen
/// by privilege rather than by position.
String? primaryRole(List<String>? authorities) =>
    (authorities?.contains(adminRole) ?? false) ? adminRole : authorities?.firstOrNull;
