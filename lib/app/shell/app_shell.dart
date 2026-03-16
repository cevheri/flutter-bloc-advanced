import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_banner.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/command_palette/command_palette_widget.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_overlay.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final menuBloc = context.read<MenuBloc>();
      if (menuBloc.state.menus.isEmpty) {
        final language = AppLocalStorageCached.language ?? 'en';
        menuBloc.add(LoadMenus(language: language));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = widget.state.uri.path;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<SidebarBloc>().add(SetActiveRoute(currentRoute));
      }
    });

    return DevConsoleShortcut(
      child: CommandPaletteShortcut(
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: ResponsiveScaffold(activeRoute: currentRoute, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
