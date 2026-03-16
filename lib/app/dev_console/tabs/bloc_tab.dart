import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';

class BlocTab extends StatefulWidget {
  const BlocTab({super.key});

  @override
  State<BlocTab> createState() => _BlocTabState();
}

class _BlocTabState extends State<BlocTab> {
  String? _filterBloc;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DevConsoleStore.instance,
      builder: (context, _) {
        final allEntries = DevConsoleStore.instance.blocEntries;
        final blocNames = allEntries.map((e) => e.blocName).toSet().toList()..sort();
        final entries = _filterBloc != null ? allEntries.where((e) => e.blocName == _filterBloc).toList() : allEntries;

        if (allEntries.isEmpty) {
          return const Center(child: Text('No BLoC transitions captured yet.'));
        }

        return Column(
          children: [
            _buildToolbar(context, entries.length, blocNames),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: entries.length,
                itemBuilder: (context, index) => _BlocTransitionTile(entry: entries[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, int count, List<String> blocNames) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text('$count transitions', style: textTheme.labelMedium),
          const SizedBox(width: AppSpacing.md),
          if (blocNames.length > 1)
            DropdownButton<String?>(
              value: _filterBloc,
              hint: Text('All BLoCs', style: textTheme.labelSmall),
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('All BLoCs', style: textTheme.labelSmall)),
                ...blocNames.map(
                  (name) => DropdownMenuItem(
                    value: name,
                    child: Text(name, style: textTheme.labelSmall),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _filterBloc = value),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Clear',
            onPressed: DevConsoleStore.instance.clearBloc,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _BlocTransitionTile extends StatelessWidget {
  const _BlocTransitionTile({required this.entry});

  final BlocTransitionEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final isError = entry.event == 'ERROR';

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
        child: Icon(
          isError ? Icons.error_outline : Icons.sync_alt,
          size: 16,
          color: isError ? colorScheme.error : colorScheme.primary,
        ),
      ),
      title: Text(entry.blocName, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        entry.event,
        style: textTheme.labelSmall?.copyWith(
          color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(entry.timestamp),
        style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      children: [
        _buildStateBox(context, 'Previous State', entry.currentState, semantic.info),
        const SizedBox(height: AppSpacing.sm),
        Center(child: Icon(Icons.arrow_downward, size: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        _buildStateBox(context, 'Next State', entry.nextState, isError ? colorScheme.error : semantic.success),
      ],
    );
  }

  Widget _buildStateBox(BuildContext context, String label, String state, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              tooltip: 'Copy',
              onPressed: () => Clipboard.setData(ClipboardData(text: state)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SelectableText(
            state,
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
