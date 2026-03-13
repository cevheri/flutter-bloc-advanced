import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies architectural dependency rules from CLAUDE.md:
///
/// - `app/` → features, shared, infrastructure, core
/// - `features/` → shared, infrastructure, core (NOT other features' internals)
/// - `shared/` → core only (NO features or infrastructure imports)
/// - `core/` → nothing (NO shared, features, or infrastructure imports)
///
/// Pre-existing violations are documented as known exceptions below.
/// These should be fixed incrementally; adding NEW exceptions is discouraged.

// ---------------------------------------------------------------------------
// Known exceptions — pre-existing tech debt to fix in future phases.
// Each entry: 'relative_file_path → imported_path_fragment'
// ---------------------------------------------------------------------------

/// core/ importing infrastructure/ (security_utils needs storage for JWT)
const _knownCoreExceptions = {'lib/core/security/security_utils.dart → infrastructure/storage/local_storage'};

/// shared/ importing app/ (theme/language dialogs depend on app-level blocs)
const _knownSharedExceptions = {
  'lib/shared/widgets/theme_selection_dialog.dart → app/theme/theme_bloc',
  'lib/shared/widgets/language_selection_dialog.dart → app/localization/language_notifier',
};

/// features/ importing other features' internals (auth↔account coupling)
const _knownCrossFeatureExceptions = {
  'lib/features/dashboard/presentation/pages/dashboard_home_page.dart → account/application/account_bloc',
  'lib/features/account/data/repositories/account_repository.dart → users/data/models/user',
  'lib/features/auth/navigation/auth_routes.dart → account/domain/repositories/account_repository',
  'lib/features/auth/application/forgot_password_bloc.dart → account/application/usecases/reset_password_usecase',
  'lib/features/auth/application/forgot_password_bloc.dart → account/domain/repositories/account_repository',
  'lib/features/auth/application/login_bloc.dart → account/application/usecases/get_account_usecase',
  'lib/features/auth/application/change_password_bloc.dart → account/application/usecases/change_password_usecase',
  'lib/features/auth/application/change_password_bloc.dart → account/data/models/change_password',
  'lib/features/auth/application/change_password_bloc.dart → account/domain/repositories/account_repository',
  'lib/features/auth/application/register_bloc.dart → account/application/usecases/register_account_usecase',
  'lib/features/auth/application/register_bloc.dart → account/domain/repositories/account_repository',
};

/// features/ importing app/ (route constants used for navigation)
const _knownFeatureAppExceptions = {
  'app/router/app_routes_constants', // all features may import this for now
};

void main() {
  group('Architecture Guard Tests', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('/generated/'))
          .toList();
    });

    test('core/ must not import from shared/, features/, infrastructure/, or app/', () {
      final violations = <String>[];
      final coreFiles = dartFiles.where((f) => f.path.contains('/core/'));

      for (final file in coreFiles) {
        final imports = _getImports(file);
        for (final import in imports) {
          if (import.contains('/shared/') ||
              import.contains('/features/') ||
              import.contains('/infrastructure/') ||
              import.contains('/app/')) {
            final key = '${_relative(file.path)} → ${_importFragment(import)}';
            if (!_isKnownException(key, _knownCoreExceptions)) {
              violations.add('${_relative(file.path)}: imports $import');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'core/ must have zero dependencies on other layers:\n${violations.join('\n')}',
      );
    });

    test('shared/ must not import from features/ or app/', () {
      final violations = <String>[];
      final sharedFiles = dartFiles.where((f) => f.path.contains('/shared/'));

      for (final file in sharedFiles) {
        final imports = _getImports(file);
        for (final import in imports) {
          if (import.contains('/features/') || import.contains('/app/')) {
            final key = '${_relative(file.path)} → ${_importFragment(import)}';
            if (!_isKnownException(key, _knownSharedExceptions)) {
              violations.add('${_relative(file.path)}: imports $import');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'shared/ must not import from features/ or app/:\n${violations.join('\n')}');
    });

    test('features/ must not import from other features/ internals', () {
      final violations = <String>[];
      final featureFiles = dartFiles.where((f) => f.path.contains('/features/'));

      for (final file in featureFiles) {
        final featureName = _extractFeatureName(file.path);
        if (featureName == null) continue;

        final imports = _getImports(file);
        for (final import in imports) {
          if (!import.contains('/features/')) continue;

          final importedFeature = _extractFeatureNameFromImport(import);
          if (importedFeature != null && importedFeature != featureName) {
            if (!import.contains('/shared/')) {
              final key = '${_relative(file.path)} → ${_importFragment(import)}';
              if (!_isKnownException(key, _knownCrossFeatureExceptions)) {
                violations.add('${_relative(file.path)} ($featureName) imports from $importedFeature: $import');
              }
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'features must not import from other features:\n${violations.join('\n')}');
    });

    test('features/ must not import from app/', () {
      final violations = <String>[];
      final featureFiles = dartFiles.where((f) => f.path.contains('/features/'));

      for (final file in featureFiles) {
        final imports = _getImports(file);
        for (final import in imports) {
          if (import.contains('/app/')) {
            final fragment = _importFragment(import);
            if (!_knownFeatureAppExceptions.any((e) => fragment.contains(e))) {
              violations.add('${_relative(file.path)}: imports $import');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'features/ must not import from app/:\n${violations.join('\n')}');
    });

    test('infrastructure/ must not import from features/ or app/', () {
      final violations = <String>[];
      final infraFiles = dartFiles.where((f) => f.path.contains('/infrastructure/'));

      for (final file in infraFiles) {
        final imports = _getImports(file);
        for (final import in imports) {
          if (import.contains('/features/') || import.contains('/app/')) {
            violations.add('${_relative(file.path)}: imports $import');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'infrastructure/ must not import from features/ or app/:\n${violations.join('\n')}',
      );
    });
  });
}

/// Extract package imports from a Dart file (ignore dart: and external packages).
List<String> _getImports(File file) {
  return file
      .readAsLinesSync()
      .where((line) => line.startsWith('import ') && line.contains('flutter_bloc_advance'))
      .map((line) {
        final match = RegExp(r"import '([^']+)'").firstMatch(line);
        return match?.group(1) ?? '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Extract feature name from a file path (e.g., lib/features/users/... → 'users').
String? _extractFeatureName(String path) {
  final match = RegExp(r'/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

/// Extract feature name from an import path.
String? _extractFeatureNameFromImport(String import) {
  final match = RegExp(r'/features/([^/]+)/').firstMatch(import);
  return match?.group(1);
}

/// Make path relative for readable output.
String _relative(String path) => path.replaceAll(RegExp(r'^.*/lib/'), 'lib/');

/// Extract a short fragment from the import path (after package:flutter_bloc_advance/).
String _importFragment(String import) {
  return import.replaceAll('package:flutter_bloc_advance/', '').replaceAll('.dart', '');
}

/// Check if a violation key matches any known exception (substring match).
bool _isKnownException(String key, Set<String> knownExceptions) {
  return knownExceptions.any(
    (exception) => key.contains(exception.split(' → ').first) && key.contains(exception.split(' → ').last),
  );
}
