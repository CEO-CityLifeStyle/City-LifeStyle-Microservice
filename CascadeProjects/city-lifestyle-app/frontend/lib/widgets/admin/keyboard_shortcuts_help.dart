import 'package:flutter/material.dart';
import '../../utils/keyboard_shortcuts.dart';

class KeyboardShortcutsHelp extends StatelessWidget {
  const KeyboardShortcutsHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 800,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Keyboard Shortcuts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShortcutSection(
                        context,
                        'Navigation',
                        [
                          const _ShortcutItem(
                            'Go to Overview',
                            NavigationIntent(0),
                          ),
                          const _ShortcutItem(
                            'Go to Performance',
                            NavigationIntent(1),
                          ),
                          const _ShortcutItem(
                            'Go to A/B Tests',
                            NavigationIntent(2),
                          ),
                          const _ShortcutItem(
                            'Go to Settings',
                            NavigationIntent(3),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildShortcutSection(
                        context,
                        'Actions',
                        [
                          const _ShortcutItem(
                            'Export Data',
                            ExportDataIntent(),
                          ),
                          const _ShortcutItem(
                            'Refresh Data',
                            RefreshDataIntent(),
                          ),
                          _ShortcutItem(
                            'Filter Data',
                            const FilterDataIntent(),
                          ),
                          _ShortcutItem(
                            'Clear Selection',
                            const ClearSelectionIntent(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutSection(
    BuildContext context,
    String title,
    List<_ShortcutItem> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...shortcuts.map((item) => _buildShortcutRow(context, item)),
      ],
    );
  }

  Widget _buildShortcutRow(BuildContext context, _ShortcutItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(item.description),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              DashboardShortcuts.getShortcutLabel(item.intent),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  final String description;
  final Intent intent;

  const _ShortcutItem(this.description, this.intent);
}
