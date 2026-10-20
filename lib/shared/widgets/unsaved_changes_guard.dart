import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:go_router/go_router.dart';

/// Whether the page [leaving] may close without asking although its form holds unsaved changes, such as when the
/// session that the page needs has ended.
typedef UnsavedChangesExitForced = bool Function(GoRouterState leaving);

/// The open pages whose forms can hold unsaved changes, by the go_router page key of each page.
///
/// Provide one above the router. [UnsavedChangesScope] registers the page it wraps, and
/// [confirmLeavingUnsavedChanges], the routes' `onExit`, asks before such a page is left with unsaved changes.
class UnsavedChangesRegistry {
  UnsavedChangesRegistry({required this._isExitForced});

  final UnsavedChangesExitForced _isExitForced;
  // A page that is entered again while its previous instance still animates out has two scopes under one key for a
  // moment; the last one registered belongs to the page the route shows.
  final _scopes = <ValueKey<String>, List<_UnsavedChangesScopeState>>{};
  final _answers = <ValueKey<String>, Future<bool>>{};

  FutureOr<bool> _confirmExit(BuildContext context, GoRouterState leaving) {
    if (_isExitForced(leaving)) return true;
    final scope = _scopes[leaving.pageKey]?.last;
    if (scope == null || !scope.widget.hasUnsavedChanges()) return true;
    // A second back or forward press while the dialog is open waits for the same answer instead of a second dialog.
    // The block body matters: whenComplete waits for a Future its callback returns, and Map.remove returns this one.
    return _answers[leaving.pageKey] ??= _ask(context).whenComplete(() {
      _answers.remove(leaving.pageKey);
    });
  }

  Future<bool> _ask(BuildContext context) async {
    return await ConfirmationDialog.show(context: context, type: DialogType.unsavedChanges) ?? false;
  }

  void _register(ValueKey<String> pageKey, _UnsavedChangesScopeState scope) {
    (_scopes[pageKey] ??= []).add(scope);
  }

  void _unregister(ValueKey<String> pageKey, _UnsavedChangesScopeState scope) {
    final scopes = _scopes[pageKey]!..remove(scope);
    if (scopes.isEmpty) _scopes.remove(pageKey);
  }
}

/// `GoRoute.onExit` for a route whose page wraps its form in an [UnsavedChangesScope]: asks before the page is left
/// with unsaved changes, whether the user leaves through the browser, the shell navigation, a back button or a
/// redirect.
FutureOr<bool> confirmLeavingUnsavedChanges(BuildContext context, GoRouterState state) {
  return context.read<UnsavedChangesRegistry>()._confirmExit(context, state);
}

/// Marks the page it sits in as one whose form can hold unsaved changes.
///
/// The page's route must use [confirmLeavingUnsavedChanges] as its `onExit`, which asks before the page is left.
/// While the form holds unsaved changes the scope also holds the system back and the iOS back swipe, and answers a
/// system back with [onBack], so that leaving goes through the route's `onExit` as well.
class UnsavedChangesScope extends StatefulWidget {
  const UnsavedChangesScope({super.key, required this.hasUnsavedChanges, required this.onBack, required this.child});

  /// Whether the page's form holds changes the user has not saved.
  final bool Function() hasUnsavedChanges;

  /// Leaves the page the way its own back button does.
  final VoidCallback onBack;

  final Widget child;

  /// Re-reads [hasUnsavedChanges] for the scope above [context]. Call it from the form's `onChanged`.
  static void formChanged(BuildContext context) {
    final scope = context.findAncestorStateOfType<_UnsavedChangesScopeState>();
    if (scope == null) {
      throw FlutterError('UnsavedChangesScope.formChanged was called with a context that has no UnsavedChangesScope.');
    }
    scope._formChanged();
  }

  @override
  State<UnsavedChangesScope> createState() => _UnsavedChangesScopeState();
}

class _UnsavedChangesScopeState extends State<UnsavedChangesScope> {
  UnsavedChangesRegistry? _registry;
  ValueKey<String>? _pageKey;
  bool _holdsChanges = false;
  bool _recheckScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = context.read<UnsavedChangesRegistry>();
    final pageKey = GoRouterState.of(context).pageKey;
    if (identical(registry, _registry) && pageKey == _pageKey) return;
    _registry?._unregister(_pageKey!, this);
    registry._register(pageKey, this);
    _registry = registry;
    _pageKey = pageKey;
  }

  @override
  void dispose() {
    _registry?._unregister(_pageKey!, this);
    super.dispose();
  }

  void _formChanged() {
    // A field reports a change before it updates its own dirty flag (reset() clears the flag last), so the form is
    // read once the frame is done.
    if (_recheckScheduled) return;
    _recheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recheckScheduled = false;
      if (!mounted) return;
      final holdsChanges = widget.hasUnsavedChanges();
      if (holdsChanges != _holdsChanges) setState(() => _holdsChanges = holdsChanges);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_holdsChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: widget.child,
    );
  }
}
