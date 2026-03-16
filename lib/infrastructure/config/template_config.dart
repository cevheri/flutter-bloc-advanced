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
  static const String prodApiUrl = 'http://localhost:8080/api';

  // Web / SEO
  static const String baseUrl = '__WEB_BASE_URL__';
  static const String githubRepo = '__GITHUB_REPO_URL__';
  static const String docsUrl = 'https://dartpilot.github.io'; // '__DOCS_URL__';

  // Author
  static const String authorName = '__AUTHOR_NAME__';
  static const String authorEmail = '__AUTHOR_EMAIL__';
  static const String authorUrl = '__AUTHOR_URL__';

  // Feature Flags
  static const bool socialLoginEnabled = false;
  static const bool multiTenancyEnabled = false;
}
