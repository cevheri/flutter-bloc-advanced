import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';

/// Mobile bottom navigation bar.
class BottomNavWidget extends StatelessWidget {
  final String activeRoute;

  const BottomNavWidget({super.key, required this.activeRoute});

  int get _currentIndex {
    if (activeRoute == ApplicationRoutesConstants.home) return 0;
    if (activeRoute.startsWith('/user')) return 1;
    if (activeRoute == ApplicationRoutesConstants.settings) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => _onTap(context, index),
      destinations: [
        NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: S.of(context).dashboard),
        NavigationDestination(icon: const Icon(Icons.people_outlined), label: S.of(context).list_user),
        NavigationDestination(icon: const Icon(Icons.settings_outlined), label: S.of(context).settings),
      ],
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        AppRouter().push(context, ApplicationRoutesConstants.home);
        break;
      case 1:
        AppRouter().push(context, ApplicationRoutesConstants.userList);
        break;
      case 2:
        AppRouter().push(context, ApplicationRoutesConstants.settings);
        break;
    }
  }
}
