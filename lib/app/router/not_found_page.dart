import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

/// Shown for locations that match no route. Mirrors go_router 17's default Material error screen, which go_router 18
/// no longer renders under the SDK MaterialApp.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(error?.toString() ?? 'page not found'),
            TextButton(onPressed: () => context.go(ApplicationRoutesConstants.home), child: const Text('Home')),
          ],
        ),
      ),
    );
  }
}
