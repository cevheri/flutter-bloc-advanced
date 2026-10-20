/// Template configuration for customizing this project.
///
/// Search for keywords starting with `__` (e.g. `__APP_NAME__`) across the
/// entire project and replace them with your own values.
/// See README.md → "Customizing for Your Project" for the full keyword list.
class TemplateConfig {
  // App identity
  static const String appName = '__APP_NAME__';
  static const String appShortName = '__APP_SHORT_NAME__';
  static const String appDescription = '__APP_DESCRIPTION__';
  static const String appKey = 'flutter_bloc_advanced';

  // API
  static const String prodApiUrl = '__PROD_API_URL__';

  // Web / SEO
  static const String baseUrl = '__WEB_BASE_URL__';

  // Links the app shows, given at build time, for example with
  // `--dart-define=GITHUB_REPO_URL=https://github.com/acme/dashboard`, or by replacing the placeholder here.
  // The app leaves out a link that is not given (see [isUnfilled]).
  static const String githubRepo = String.fromEnvironment('GITHUB_REPO_URL', defaultValue: '__GITHUB_REPO_URL__');
  static const String docsUrl = String.fromEnvironment('DOCS_URL', defaultValue: '__DOCS_URL__');
  static const String sponsorUrl = String.fromEnvironment('SPONSOR_URL', defaultValue: '__SPONSOR_URL__');

  // Author
  static const String authorName = '__AUTHOR_NAME__';
  static const String authorEmail = '__AUTHOR_EMAIL__';
  static const String authorUrl = '__AUTHOR_URL__';

  // Feature Flags
  static const bool socialLoginEnabled = false;
  static const bool multiTenancyEnabled = false;

  /// Whether [value] has not been filled in: it is empty, or still a placeholder such as `__KEYWORD__`.
  static bool isUnfilled(String value) => value.isEmpty || _placeholder.hasMatch(value);

  /// `__`, a key of upper-case letters, digits and `_` that starts with a letter, and `__`: the placeholders
  /// scripts/check_web_placeholders.sh finds in a web build.
  static final _placeholder = RegExp(r'^__[A-Z][A-Z0-9_]*__$');
}
