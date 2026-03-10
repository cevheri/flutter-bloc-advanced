import 'package:flutter/material.dart';
import '../tokens/app_sizes.dart';
import 'app_button.dart' show AppComponentSize;

/// Status dot for avatar.
enum AppAvatarStatus { online, offline, away, none }

/// Avatar with image, fallback initials, and optional status dot.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AppComponentSize size;
  final AppAvatarStatus status;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppComponentSize.md,
    this.status = AppAvatarStatus.none,
  });

  double get _diameter {
    switch (size) {
      case AppComponentSize.sm:
        return AppSizes.avatarSm;
      case AppComponentSize.md:
        return AppSizes.avatarMd;
      case AppComponentSize.lg:
        return AppSizes.avatarLg;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppComponentSize.sm:
        return 12;
      case AppComponentSize.md:
        return 14;
      case AppComponentSize.lg:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CircleAvatar(
          radius: _diameter / 2,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials ?? '?',
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        if (status != AppAvatarStatus.none)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _diameter * 0.3,
              height: _diameter * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Color get _statusColor {
    switch (status) {
      case AppAvatarStatus.online:
        return const Color(0xFF4CAF50);
      case AppAvatarStatus.away:
        return const Color(0xFFFFC107);
      case AppAvatarStatus.offline:
        return const Color(0xFF9E9E9E);
      case AppAvatarStatus.none:
        return Colors.transparent;
    }
  }
}

/// Reuse AppComponentSize from app_button.dart.
/// Import from app_button.dart to avoid duplication.
