import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/command_palette/command_palette_widget.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentRoute = state.uri.path;

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
