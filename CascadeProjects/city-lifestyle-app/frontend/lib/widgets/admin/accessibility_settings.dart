import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

class AccessibilitySettings extends StatelessWidget {
  final double textScaleFactor;
  final bool highContrastMode;
  final bool reduceMotion;
  final bool screenReaderMode;
  final Function(double) onTextScaleChanged;
  final Function(bool) onHighContrastChanged;
  final Function(bool) onReduceMotionChanged;
  final Function(bool) onScreenReaderModeChanged;

  const AccessibilitySettings({
    Key? key,
    required this.textScaleFactor,
    required this.highContrastMode,
    required this.reduceMotion,
    required this.screenReaderMode,
    required this.onTextScaleChanged,
    required this.onHighContrastChanged,
    required this.onReduceMotionChanged,
    required this.onScreenReaderModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.wrapForAccessibility(
      label: 'Accessibility Settings',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accessibility',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _buildTextScaling(context),
              const SizedBox(height: 24),
              _buildToggleSettings(context),
              const SizedBox(height: 24),
              _buildAccessibilityGuide(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextScaling(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Size',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.text_fields, size: 20),
            Expanded(
              child: Slider(
                value: textScaleFactor,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                label: '${(textScaleFactor * 100).round()}%',
                onChanged: onTextScaleChanged,
              ),
            ),
            const Icon(Icons.text_fields, size: 24),
          ],
        ),
        Center(
          child: Text(
            'Sample Text',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) *
                  textScaleFactor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('High Contrast Mode'),
          subtitle: const Text('Increase contrast for better visibility'),
          value: highContrastMode,
          onChanged: onHighContrastChanged,
        ),
        SwitchListTile(
          title: const Text('Reduce Motion'),
          subtitle: const Text('Minimize animations and motion effects'),
          value: reduceMotion,
          onChanged: onReduceMotionChanged,
        ),
        SwitchListTile(
          title: const Text('Screen Reader Optimization'),
          subtitle: const Text('Enhance compatibility with screen readers'),
          value: screenReaderMode,
          onChanged: onScreenReaderModeChanged,
        ),
      ],
    );
  }

  Widget _buildAccessibilityGuide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keyboard Navigation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildShortcutRow(
          context,
          'Tab',
          'Move between interactive elements',
        ),
        _buildShortcutRow(
          context,
          'Space/Enter',
          'Activate buttons and controls',
        ),
        _buildShortcutRow(
          context,
          'Arrow Keys',
          'Navigate within components',
        ),
        _buildShortcutRow(
          context,
          'Esc',
          'Close dialogs or menus',
        ),
      ],
    );
  }

  Widget _buildShortcutRow(
    BuildContext context,
    String shortcut,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
              shortcut,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
