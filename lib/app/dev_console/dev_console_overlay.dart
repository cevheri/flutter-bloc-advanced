import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/network_tab.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/bloc_tab.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/storage_tab.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/environment_tab.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_tab.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';

/// Keyboard shortcut wrapper that listens for Ctrl+Shift+D to open the developer console.
///
/// Only active in debug mode. Wraps the child widget with keyboard shortcut listeners.
class DevConsoleShortcut extends StatelessWidget {
  final Widget child;
  const DevConsoleShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD):
            const _OpenDevConsoleIntent(),
      },
      child: Actions(
        actions: {
          _OpenDevConsoleIntent: CallbackAction<_OpenDevConsoleIntent>(
            onInvoke: (_) {
              DevConsoleOverlay.show(context);
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _OpenDevConsoleIntent extends Intent {
  const _OpenDevConsoleIntent();
}

/// The in-app developer console overlay.
///
/// Shows a bottom sheet with 4 tabs: Network, BLoC, Storage, Environment.
class DevConsoleOverlay {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => const _DevConsolePanel(),
    );
  }
}

class _DevConsolePanel extends StatefulWidget {
  const _DevConsolePanel();

  @override
  State<_DevConsolePanel> createState() => _DevConsolePanelState();
}

class _DevConsolePanelState extends State<_DevConsolePanel> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.http, size: 18), text: 'Network'),
    Tab(icon: Icon(Icons.sync_alt, size: 18), text: 'BLoC'),
    Tab(icon: Icon(Icons.history, size: 18), text: 'Time Travel'),
    Tab(icon: Icon(Icons.storage, size: 18), text: 'Storage'),
    Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Env'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
          child: Row(
            children: [
              Icon(Icons.developer_mode, size: 20, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Developer Console', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                tooltip: 'Clear all',
                onPressed: () {
                  DevConsoleStore.instance.clearAll();
                  TimeTravelStore.instance.clear();
                  if (mounted) setState(() {});
                },
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: false,
          labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: textTheme.labelSmall,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 1,
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [NetworkTab(), BlocTab(), TimeTravelTab(), StorageTab(), EnvironmentTab()],
          ),
        ),
      ],
    );
  }
}
