import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/presentation/shell/command_palette/command_palette_widget.dart';
import 'package:go_router/go_router.dart';
import 'responsive_scaffold.dart';

/// The main shell widget used as ShellRoute builder.
/// Wraps authenticated pages with sidebar, top bar, command palette, and responsive layout.
class AppShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const AppShell({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentRoute = state.uri.path;

    // Update active route in SidebarBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<SidebarBloc>().add(SetActiveRoute(currentRoute));
      }
    });

    return CommandPaletteShortcut(
      child: ResponsiveScaffold(activeRoute: currentRoute, child: child),
    );
  }
}
