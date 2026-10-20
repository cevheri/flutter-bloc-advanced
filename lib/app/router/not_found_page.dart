import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:go_router/go_router.dart';

/// Shown for locations that match no route. Mirrors go_router 17's default Material error screen, which go_router 18
/// no longer renders under the SDK MaterialApp.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).not_found_title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(error?.toString() ?? S.of(context).not_found_message),
            TextButton(onPressed: () => context.go(ApplicationRoutesConstants.home), child: Text(S.of(context).home)),
          ],
        ),
      ),
    );
  }
}
