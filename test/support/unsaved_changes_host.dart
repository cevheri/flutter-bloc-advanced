import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:go_router/go_router.dart';

/// Provides the [UnsavedChangesRegistry] that a page with an `UnsavedChangesScope` needs, as `App` does above its
/// router. It forces no exit; a test of a session that ends pumps `App` instead.
Widget withUnsavedChangesRegistry(Widget app) {
  return RepositoryProvider<UnsavedChangesRegistry>(
    create: (_) => UnsavedChangesRegistry(isExitForced: (_) => false),
    child: app,
  );
}

/// A router whose one page is [page], for a test that hosts a page with an `UnsavedChangesScope`, which must sit in
/// a go_router page.
GoRouter singlePageRouter(Widget page) => GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => page)],
);
