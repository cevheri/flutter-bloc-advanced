import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';

class NetworkTab extends StatelessWidget {
  const NetworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DevConsoleStore.instance,
      builder: (context, _) {
        final entries = DevConsoleStore.instance.networkEntries;

        if (entries.isEmpty) {
          return const Center(child: Text('No network requests captured yet.'));
        }

        return Column(
          children: [
            _buildToolbar(context, entries.length),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: entries.length,
                itemBuilder: (context, index) => _NetworkEntryTile(entry: entries[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text('$count requests', style: Theme.of(context).textTheme.labelMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Clear',
            onPressed: DevConsoleStore.instance.clearNetwork,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _NetworkEntryTile extends StatelessWidget {
  const _NetworkEntryTile({required this.entry});

  final NetworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    final statusColor = _statusColor(entry, semantic, colorScheme);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      leading: _MethodBadge(method: entry.method),
      title: Text(
        _shortenUrl(entry.url),
        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (entry.statusCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${entry.statusCode}',
                style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          if (entry.duration != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text('${entry.duration!.inMilliseconds}ms', style: textTheme.labelSmall),
          ],
          if (!entry.isComplete) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: colorScheme.primary),
            ),
          ],
          if (entry.error != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.error_outline, size: 14, color: colorScheme.error),
          ],
        ],
      ),
      trailing: Text(
        _formatTime(entry.startTime),
        style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      children: [
        _buildDetailSection(context, 'URL', entry.url),
        if (entry.requestHeaders.isNotEmpty)
          _buildDetailSection(context, 'Request Headers', _formatMap(entry.requestHeaders)),
        if (entry.requestBody != null) _buildDetailSection(context, 'Request Body', entry.requestBody!),
        if (entry.responseHeaders.isNotEmpty)
          _buildDetailSection(context, 'Response Headers', _formatMap(entry.responseHeaders)),
        if (entry.responseBody != null) _buildDetailSection(context, 'Response Body', entry.responseBody!),
        if (entry.error != null) _buildDetailSection(context, 'Error', entry.error!, isError: true),
      ],
    );
  }

  Widget _buildDetailSection(BuildContext context, String label, String content, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
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
            decoration: BoxDecoration(
              color: isError ? colorScheme.errorContainer.withAlpha(60) : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SelectableText(
              content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isError ? colorScheme.error : null,
              ),
              maxLines: 20,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(NetworkEntry entry, SemanticColors semantic, ColorScheme colorScheme) {
    if (entry.error != null) return colorScheme.error;
    final code = entry.statusCode;
    if (code == null) return colorScheme.onSurfaceVariant;
    if (code < 300) return semantic.success;
    if (code < 400) return semantic.warning;
    return colorScheme.error;
  }

  String _shortenUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = switch (method.toUpperCase()) {
      'GET' => const Color(0xFF2196F3),
      'POST' => const Color(0xFF4CAF50),
      'PUT' => const Color(0xFFFF9800),
      'PATCH' => const Color(0xFF9C27B0),
      'DELETE' => const Color(0xFFF44336),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        method.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
