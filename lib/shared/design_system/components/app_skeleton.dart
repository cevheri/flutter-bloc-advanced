import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_radius.dart';

/// Skeleton shape variants.
enum AppSkeletonShape { text, circle, rectangle, card, listTile }

/// Shimmer-based loading placeholder.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final AppSkeletonShape shape;
  final BorderRadius? borderRadius;

  const AppSkeleton({super.key, this.width, this.height, this.shape = AppSkeletonShape.rectangle, this.borderRadius});

  /// A text-line skeleton.
  const AppSkeleton.text({super.key, this.width = 200, this.height = 14})
    : shape = AppSkeletonShape.text,
      borderRadius = null;

  /// A circular skeleton (avatar placeholder).
  const AppSkeleton.circle({super.key, double diameter = 40})
    : width = diameter,
      height = diameter,
      shape = AppSkeletonShape.circle,
      borderRadius = null;

  /// A card-shaped skeleton.
  const AppSkeleton.card({super.key, this.width, this.height = 120})
    : shape = AppSkeletonShape.card,
      borderRadius = null;

  /// A list tile skeleton.
  factory AppSkeleton.listTile({Key? key}) {
    return AppSkeleton._listTile(key: key);
  }

  const AppSkeleton._listTile({super.key})
    : width = null,
      height = 64,
      shape = AppSkeletonShape.listTile,
      borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    if (shape == AppSkeletonShape.listTile) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape == AppSkeletonShape.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: shape == AppSkeletonShape.circle
              ? null
              : borderRadius ?? BorderRadius.circular(shape == AppSkeletonShape.card ? AppRadius.md : 4),
        ),
      ),
    );
  }
}
