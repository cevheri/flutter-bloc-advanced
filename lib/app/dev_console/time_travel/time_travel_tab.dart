import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';

/// Time-Travel Debugging tab for the Developer Console.
///
/// Shows state snapshots per BLoC with rewind, replay, diff, and export capabilities.
class TimeTravelTab extends StatefulWidget {
  const TimeTravelTab({super.key});

  @override
  State<TimeTravelTab> createState() => _TimeTravelTabState();
}

class _TimeTravelTabState extends State<TimeTravelTab> {
  String? _selectedBloc;
  bool _isReplaying = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TimeTravelStore.instance,
      builder: (context, _) {
        final store = TimeTravelStore.instance;
        final blocNames = store.blocNames;

        if (blocNames.isEmpty) {
          return const Center(child: Text('No state transitions recorded yet.'));
        }

        final selectedBloc = _selectedBloc ?? (blocNames.isNotEmpty ? blocNames.first : null);
        final snapshots = selectedBloc != null ? store.snapshotsFor(selectedBloc) : <StateSnapshot>[];

        return Column(
          children: [
            _buildToolbar(context, blocNames, selectedBloc, snapshots.length),
            const Divider(height: 1),
            Expanded(
              child: snapshots.isEmpty
                  ? const Center(child: Text('No snapshots for this BLoC.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      itemCount: snapshots.length,
                      itemBuilder: (context, index) => _SnapshotTile(
                        snapshot: snapshots[index],
                        index: index,
                        isFirst: index == 0,
                        onRewind: () => _rewindTo(selectedBloc!, snapshots[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, List<String> blocNames, String? selectedBloc, int count) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final store = TimeTravelStore.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // BLoC selector
          DropdownButton<String>(
            value: selectedBloc,
            hint: Text('Select BLoC', style: textTheme.labelSmall),
            underline: const SizedBox.shrink(),
            isDense: true,
            items: blocNames
                .map(
                  (name) => DropdownMenuItem(
                    value: name,
                    child: Text(name, style: textTheme.labelSmall),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedBloc = value),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$count snapshots', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          // Replay button
          if (selectedBloc != null && count > 1)
            IconButton(
              icon: Icon(
                _isReplaying ? Icons.stop : Icons.play_arrow,
                size: 18,
                color: _isReplaying ? colorScheme.error : colorScheme.primary,
              ),
              tooltip: _isReplaying ? 'Stop replay' : 'Replay transitions',
              onPressed: () => _isReplaying ? _stopReplay() : _startReplay(selectedBloc),
              visualDensity: VisualDensity.compact,
            ),
          // Export button
          IconButton(
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Export as JSON',
            onPressed: () {
              final json = store.exportAsJson();
              Clipboard.setData(ClipboardData(text: json));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Timeline exported to clipboard'), duration: Duration(seconds: 2)),
                );
              }
            },
            visualDensity: VisualDensity.compact,
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Clear',
            onPressed: () => store.clear(selectedBloc),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _rewindTo(String blocName, StateSnapshot snapshot) {
    final success = TimeTravelStore.instance.rewindTo(blocName, snapshot);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Rewound $blocName to previous state' : 'Cannot rewind — BLoC not available'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startReplay(String blocName) async {
    final snapshots = TimeTravelStore.instance.snapshotsFor(blocName).reversed.toList();
    if (snapshots.length < 2) return;

    setState(() => _isReplaying = true);

    for (int i = 0; i < snapshots.length; i++) {
      if (!_isReplaying || !mounted) break;
      TimeTravelStore.instance.rewindTo(blocName, snapshots[i]);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (mounted) setState(() => _isReplaying = false);
  }

  void _stopReplay() {
    setState(() => _isReplaying = false);
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({required this.snapshot, required this.index, required this.isFirst, required this.onRewind});

  final StateSnapshot snapshot;
  final int index;
  final bool isFirst;
  final VoidCallback onRewind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isFirst ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: Center(
              child: isFirst
                  ? Icon(Icons.circle, size: 8, color: colorScheme.onPrimary)
                  : Text('$index', style: textTheme.labelSmall?.copyWith(fontSize: 9)),
            ),
          ),
        ],
      ),
      title: Text(
        snapshot.event,
        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatTime(snapshot.timestamp),
        style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.replay, size: 16),
        tooltip: 'Rewind to this state',
        onPressed: onRewind,
        visualDensity: VisualDensity.compact,
      ),
      children: [
        // State diff view
        _buildDiffView(context, semantic, colorScheme, textTheme),
      ],
    );
  }

  Widget _buildDiffView(BuildContext context, SemanticColors semantic, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Previous state
        _buildStateBlock(context, 'Before', snapshot.previousState, colorScheme.error.withAlpha(20), colorScheme),
        const SizedBox(height: AppSpacing.sm),
        Center(child: Icon(Icons.arrow_downward, size: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        // Next state
        _buildStateBlock(context, 'After', snapshot.state, semantic.success.withAlpha(20), colorScheme),
      ],
    );
  }

  Widget _buildStateBlock(BuildContext context, String label, String content, Color bgColor, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              tooltip: 'Copy',
              onPressed: () => Clipboard.setData(ClipboardData(text: content)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: SelectableText(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11),
            maxLines: 15,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
  }
}
