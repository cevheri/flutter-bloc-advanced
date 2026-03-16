import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';

class StorageTab extends StatefulWidget {
  const StorageTab({super.key});

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab> {
  Map<String, String> _storageData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    final data = <String, String>{};
    for (final key in StorageKeys.values) {
      final value = await AppLocalStorage().read(key.name);
      if (value != null) {
        data[key.name] = _maskSensitive(key.name, value.toString());
      }
    }
    if (mounted) {
      setState(() {
        _storageData = data;
        _loading = false;
      });
    }
  }

  String _maskSensitive(String key, String value) {
    if (key == StorageKeys.jwtToken.name && value.length > 20) {
      return '${value.substring(0, 10)}...[masked]...${value.substring(value.length - 10)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_storageData.isEmpty) {
      return const Center(child: Text('No data in local storage.'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text('${_storageData.length} keys', style: textTheme.labelMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: () {
                  setState(() => _loading = true);
                  _loadStorage();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _storageData.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final key = _storageData.keys.elementAt(index);
              final value = _storageData[key]!;
              return _StorageKeyValueCard(keyName: key, value: value, colorScheme: colorScheme, textTheme: textTheme);
            },
          ),
        ),
      ],
    );
  }
}

class _StorageKeyValueCard extends StatelessWidget {
  const _StorageKeyValueCard({
    required this.keyName,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  final String keyName;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, size: 14, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(keyName, style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                tooltip: 'Copy value',
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(value, style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }
}
