import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/presentation/design_system/theme/app_theme_palette.dart';
import 'package:flutter_bloc_advance/presentation/design_system/theme/app_theme.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => const ThemeSelectionDialog());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 12),
                    Text('Choose Theme', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select your preferred theme style',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildThemeCard(
                          context,
                          title: AppThemePalette.classic.title,
                          description: AppThemePalette.classic.description,
                          icon: AppThemePalette.classic.icon,
                          palette: AppThemePalette.classic,
                          isSelected: state.palette == AppThemePalette.classic,
                        ),
                        const SizedBox(height: 16),
                        _buildThemeCard(
                          context,
                          title: AppThemePalette.nature.title,
                          description: AppThemePalette.nature.description,
                          icon: AppThemePalette.nature.icon,
                          palette: AppThemePalette.nature,
                          isSelected: state.palette == AppThemePalette.nature,
                        ),
                        const SizedBox(height: 16),
                        _buildThemeCard(
                          context,
                          title: AppThemePalette.sunset.title,
                          description: AppThemePalette.sunset.description,
                          icon: AppThemePalette.sunset.icon,
                          palette: AppThemePalette.sunset,
                          isSelected: state.palette == AppThemePalette.sunset,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Apply')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required AppThemePalette palette,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          _applyTheme(context, palette);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ],
              ),
              const SizedBox(height: 16),
              _buildThemePreview(context, palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, AppThemePalette palette) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Light mode preview
          Expanded(child: _buildPreviewSide(context, isLight: true, palette: palette)),
          // Divider
          Container(width: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          // Dark mode preview
          Expanded(child: _buildPreviewSide(context, isLight: false, palette: palette)),
        ],
      ),
    );
  }

  Widget _buildPreviewSide(BuildContext context, {required bool isLight, required AppThemePalette palette}) {
    // Create a temporary theme for preview using the selected palette
    final previewTheme = isLight ? AppTheme.light(palette) : AppTheme.dark(palette);

    return Theme(
      data: previewTheme,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: previewTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: isLight ? const Radius.circular(8) : Radius.zero,
            bottomLeft: isLight ? const Radius.circular(8) : Radius.zero,
            topRight: !isLight ? const Radius.circular(8) : Radius.zero,
            bottomRight: !isLight ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar preview
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: previewTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // Content preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: 30,
                    decoration: BoxDecoration(
                      color: previewTheme.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 6,
                    width: 20,
                    decoration: BoxDecoration(
                      color: previewTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: 25,
                    decoration: BoxDecoration(
                      color: previewTheme.colorScheme.onSurface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            // Theme indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLight ? Icons.light_mode : Icons.dark_mode,
                  size: 12,
                  color: previewTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyTheme(BuildContext context, AppThemePalette palette) {
    // Apply theme using bloc
    context.read<ThemeBloc>().add(ChangeThemePalette(palette: palette));

    // Show feedback with a brief highlight animation
    // The BlocBuilder will automatically update the UI to show the selected theme
  }
}
