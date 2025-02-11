import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardShortcuts {
  static final Map<ShortcutActivator, Intent> shortcuts = {
    // Navigation shortcuts
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
        const NavigationIntent(0),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
        const NavigationIntent(1),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
        const NavigationIntent(2),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4):
        const NavigationIntent(3),

    // Action shortcuts
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE):
        const ExportDataIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
        const RefreshDataIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyK):
        const ShowShortcutsIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape):
        const DismissIntent(),
  };

  static final Map<Type, Action<Intent>> actions = {
    NavigationIntent: CallbackAction<NavigationIntent>(
      onInvoke: (intent) => intent.index,
    ),
    ExportDataIntent: CallbackAction<ExportDataIntent>(
      onInvoke: (intent) => null,
    ),
    RefreshDataIntent: CallbackAction<RefreshDataIntent>(
      onInvoke: (intent) => null,
    ),
    ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(
      onInvoke: (intent) => null,
    ),
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (intent) => null,
    ),
  };

  static final Map<Type, String> shortcutDescriptions = {
    NavigationIntent: 'Navigate to tab',
    ExportDataIntent: 'Export data',
    RefreshDataIntent: 'Refresh data',
    ShowShortcutsIntent: 'Show keyboard shortcuts',
    DismissIntent: 'Close dialog/panel',
  };

  static String getShortcutLabel(Intent intent) {
    final entry = shortcuts.entries
        .firstWhere((entry) => entry.value.runtimeType == intent.runtimeType);
    return _formatKeySet(entry.key as LogicalKeySet);
  }

  static String getShortcutDescription(Intent intent) {
    return shortcutDescriptions[intent.runtimeType] ?? '';
  }

  static String _formatKeySet(LogicalKeySet keySet) {
    final keys = keySet.keys.map((key) {
      final keyLabel = key.keyLabel;
      if (key == LogicalKeyboardKey.alt) return 'Alt';
      if (key == LogicalKeyboardKey.control) return 'Ctrl';
      if (key == LogicalKeyboardKey.escape) return 'Esc';
      return keyLabel;
    }).join(' + ');
    return keys;
  }

  static void showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ShortcutsDialog(),
    );
  }
}

class NavigationIntent extends Intent {
  final int index;
  const NavigationIntent(this.index);
}

class ExportDataIntent extends Intent {
  const ExportDataIntent();
}

class RefreshDataIntent extends Intent {
  const RefreshDataIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

class DismissIntent extends Intent {
  const DismissIntent();
}

class ShortcutTooltip extends StatelessWidget {
  final Widget child;
  final Intent intent;

  const ShortcutTooltip({
    Key? key,
    required this.child,
    required this.intent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shortcut = DashboardShortcuts.getShortcutLabel(intent);
    final description = DashboardShortcuts.getShortcutDescription(intent);
    return Tooltip(
      message: '$description ($shortcut)',
      child: child,
    );
  }
}

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = DashboardShortcuts.shortcuts.entries.toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShortcutSection(
                      'Navigation',
                      shortcuts.where((e) => e.value is NavigationIntent),
                    ),
                    const SizedBox(height: 16),
                    _buildShortcutSection(
                      'Actions',
                      shortcuts.where((e) => e.value is! NavigationIntent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection(
    String title,
    Iterable<MapEntry<ShortcutActivator, Intent>> shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...shortcuts.map((entry) {
          final shortcut = DashboardShortcuts._formatKeySet(entry.key as LogicalKeySet);
          final description = DashboardShortcuts.getShortcutDescription(entry.value);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(description),
                ),
                Expanded(
                  child: Text(
                    shortcut,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
