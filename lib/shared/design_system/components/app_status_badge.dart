import 'package:flutter/material.dart';

/// A subtle status badge with transparent background derived from the given color.
///
/// Unlike [AppBadge] which uses predefined theme variants, [AppStatusBadge]
/// accepts any color and creates a ghost-style badge suitable for active/inactive,
/// enabled/disabled, or custom status indicators.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(51), width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}
