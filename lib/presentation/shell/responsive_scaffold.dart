import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/sidebar/sidebar_bloc.dart';
import '../design_system/tokens/app_breakpoints.dart';
import 'sidebar/sidebar_widget.dart';
import 'top_bar/top_bar_widget.dart';
import 'bottom_nav/bottom_nav_widget.dart';

/// Switches layout based on screen width:
/// - Desktop (>=1024): Sidebar + TopBar + Content
/// - Tablet (768-1024): Rail sidebar + TopBar + Content
/// - Mobile (<768): TopBar with hamburger + Content + BottomNav
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String activeRoute;

  const ResponsiveScaffold({super.key, required this.child, required this.activeRoute});

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
    return Scaffold(
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            FocusTraversalOrder(order: const NumericFocusOrder(1), child: const SidebarWidget()),
            const VerticalDivider(width: 1, thickness: 0.5),
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
    // Auto-collapse sidebar on tablet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sidebarBloc = context.read<SidebarBloc>();
      if (!sidebarBloc.state.isCollapsed) {
        sidebarBloc.add(const CollapseSidebar());
      }
    });

    return Scaffold(
      body: Row(
        children: [
          const SidebarWidget(),
          const VerticalDivider(width: 1, thickness: 0.5),
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
    return Scaffold(
      body: Column(
        children: [
          TopBarWidget(title: _routeToTitle(activeRoute), onMenuTap: () => Scaffold.of(context).openDrawer()),
          Expanded(child: child),
        ],
      ),
      drawer: const Drawer(child: SidebarWidget()),
      bottomNavigationBar: BottomNavWidget(activeRoute: activeRoute),
    );
  }

  String _routeToTitle(String route) {
    if (route == '/') return 'Dashboard';
    final segment = route.split('/').where((s) => s.isNotEmpty).first;
    return segment.replaceFirst(segment[0], segment[0].toUpperCase());
  }
}
