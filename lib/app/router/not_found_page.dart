import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:go_router/go_router.dart';

/// Shown for locations that match no route. Mirrors the layout of go_router 17's default Material error screen, which
/// go_router 18 no longer renders under the SDK MaterialApp, with a message in the app language in place of the
/// router's error, which the router logs.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).not_found_title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(S.of(context).not_found_message),
            TextButton(onPressed: () => context.go(ApplicationRoutesConstants.home), child: Text(S.of(context).home)),
          ],
        ),
      ),
    );
  }
}
