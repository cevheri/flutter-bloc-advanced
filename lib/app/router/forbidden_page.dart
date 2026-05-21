import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:go_router/go_router.dart';

/// Surfaces when an authenticated user navigates to a route requiring
/// a role they do not have. Dedicated route (vs an inline error
/// dialog) so back-navigation behaves sanely and the URL state matches
/// what the user sees.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.forbidden_title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 72, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(s.forbidden_message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(ApplicationRoutesConstants.home),
                child: Text(s.forbidden_back_home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
