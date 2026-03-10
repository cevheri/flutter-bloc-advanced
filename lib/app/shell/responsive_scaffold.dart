import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/bottom_nav/bottom_nav_widget.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key, required this.child, required this.activeRoute});

  final Widget child;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (AppBreakpoints.isDesktop(width)) {
          return _desktopLayout(context);
        }
        if (AppBreakpoints.isTablet(width)) {
          return _tabletLayout(context);
        }
        return _mobileLayout(context);
      },
    );
  }

  Widget _desktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: colorScheme.outlineVariant, width: 1)),
                ),
                child: const SidebarWidget(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  FocusTraversalOrder(order: const NumericFocusOrder(2), child: const TopBarWidget()),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: Expanded(child: child),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabletLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sidebarBloc = context.read<SidebarBloc>();
      if (!sidebarBloc.state.isCollapsed) {
        sidebarBloc.add(const CollapseSidebar());
      }
    });

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: colorScheme.outlineVariant, width: 1)),
            ),
            child: const SidebarWidget(),
          ),
          Expanded(
            child: Column(
              children: [
                const TopBarWidget(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) {
        return Scaffold(
          body: Column(
            children: [
              TopBarWidget(
                title: _routeToTitle(activeRoute),
                onMenuTap: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
              Expanded(child: child),
            ],
          ),
          drawer: const Drawer(child: SidebarWidget()),
          bottomNavigationBar: BottomNavWidget(activeRoute: activeRoute),
        );
      },
    );
  }

  String _routeToTitle(String route) {
    if (route == '/') return 'Dashboard';

    final segments = route.split('/').where((value) => value.isNotEmpty).toList();
    if (segments.isEmpty) {
      return 'Dashboard';
    }
    final segment = segments.first;

    return segment.replaceFirst(segment[0], segment[0].toUpperCase());
  }
}
