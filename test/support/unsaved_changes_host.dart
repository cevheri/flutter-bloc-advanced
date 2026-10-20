import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';

/// Provides the [UnsavedChangesRegistry] that a page with an `UnsavedChangesScope` needs, as `App` does above its
/// router. It forces no exit; a test of a session that ends pumps `App` instead.
Widget withUnsavedChangesRegistry(Widget app) {
  return RepositoryProvider<UnsavedChangesRegistry>(
    create: (_) => UnsavedChangesRegistry(isExitForced: (_) => false),
    child: app,
  );
}
