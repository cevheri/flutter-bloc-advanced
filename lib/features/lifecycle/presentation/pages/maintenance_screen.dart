import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';

/// Full-screen maintenance mode overlay.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, this.message, this.estimatedEnd, this.checking = false});

  static final _log = AppLogger.getLogger('MaintenanceScreen');

  /// The message from the app config, shown as the server wrote it, in place of the default message.
  final String? message;

  /// When the app config expects the maintenance to end, as an ISO 8601 date and time.
  final String? estimatedEnd;

  /// Whether the app checks the config again, so the retry button shows that it is busy.
  final bool checking;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  /// [MaintenanceScreen.estimatedEnd] in the device time zone, parsed once per value so that a rejected value is
  /// logged once and not on every rebuild.
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _end = _parseEstimatedEnd(widget.estimatedEnd);
  }

  @override
  void didUpdateWidget(MaintenanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estimatedEnd != oldWidget.estimatedEnd) _end = _parseEstimatedEnd(widget.estimatedEnd);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = S.of(context);
    final end = _formatEstimatedEnd(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 80, color: colorScheme.tertiary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.maintenance_title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.message ?? l10n.maintenance_message,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (end != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.maintenance_estimated_end(end),
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l10n.maintenance_retry,
                icon: Icons.refresh,
                variant: AppButtonVariant.outlined,
                isLoading: widget.checking,
                onPressed: () =>
                    context.read<LifecycleBloc>().add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.retry)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [value] as a local date and time, or null when the config gives none. A value that is not an ISO 8601 date and
  /// time is a server misconfiguration: it is logged and left out.
  static DateTime? _parseEstimatedEnd(String? value) {
    if (value == null) return null;
    final end = DateTime.tryParse(value)?.toLocal();
    if (end == null) MaintenanceScreen._log.error('Rejected maintenanceEstimatedEnd from app config: {}', [value]);
    return end;
  }

  /// The end time as a date and time in the app language, or null when there is none to show.
  String? _formatEstimatedEnd(BuildContext context) {
    final end = _end;
    if (end == null) return null;
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '${localizations.formatMediumDate(end)} $time';
  }
}
