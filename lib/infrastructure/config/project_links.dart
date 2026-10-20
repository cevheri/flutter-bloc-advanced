import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';

/// The project's own pages that the app links to: its source repository, its documentation and its sponsor page.
///
/// A link is null while its value has not been filled in ([TemplateConfig.isUnfilled]), so the app leaves the link out
/// instead of showing one that leads nowhere. The app reads the values given at build time ([TemplateConfig]), which
/// are compile-time constants, so a test that needs other values passes its own through `AppDependencies`.
final class ProjectLinks {
  const ProjectLinks({
    this._repository = TemplateConfig.githubRepo,
    this._docs = TemplateConfig.docsUrl,
    this._sponsor = TemplateConfig.sponsorUrl,
  });

  final String _repository;
  final String _docs;
  final String _sponsor;

  /// The source repository, such as `https://github.com/acme/dashboard`.
  String? get repositoryUrl => _filled(_repository);

  /// The documentation website.
  String? get docsUrl => _filled(_docs);

  /// The page that takes sponsorships, such as `https://github.com/sponsors/acme`.
  String? get sponsorUrl => _filled(_sponsor);

  static String? _filled(String value) => TemplateConfig.isUnfilled(value) ? null : value;
}
