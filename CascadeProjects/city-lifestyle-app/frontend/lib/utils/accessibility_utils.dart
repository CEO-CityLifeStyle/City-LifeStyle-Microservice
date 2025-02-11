import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityUtils {
  static const String _highContrastKey = 'high_contrast_mode';
  static const String _textScaleKey = 'text_scale_factor';
  static const String _reducedMotionKey = 'reduced_motion';
  static const String _screenReaderKey = 'screen_reader_announcements';

  static late SharedPreferences _prefs;
  static final ValueNotifier<bool> highContrastMode = ValueNotifier<bool>(false);
  static final ValueNotifier<double> textScaleFactor = ValueNotifier<double>(1.0);
  static final ValueNotifier<bool> reducedMotion = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> screenReaderEnabled = ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved preferences
    highContrastMode.value = _prefs.getBool(_highContrastKey) ?? false;
    textScaleFactor.value = _prefs.getDouble(_textScaleKey) ?? 1.0;
    reducedMotion.value = _prefs.getBool(_reducedMotionKey) ?? false;
    screenReaderEnabled.value = _prefs.getBool(_screenReaderKey) ?? false;
  }

  static Future<void> setHighContrastMode(bool enabled) async {
    await _prefs.setBool(_highContrastKey, enabled);
    highContrastMode.value = enabled;
  }

  static Future<void> setTextScaleFactor(double scale) async {
    if (scale >= 0.8 && scale <= 2.0) {
      await _prefs.setDouble(_textScaleKey, scale);
      textScaleFactor.value = scale;
    }
  }

  static Future<void> setReducedMotion(bool enabled) async {
    await _prefs.setBool(_reducedMotionKey, enabled);
    reducedMotion.value = enabled;
  }

  static Future<void> setScreenReaderEnabled(bool enabled) async {
    await _prefs.setBool(_screenReaderKey, enabled);
    screenReaderEnabled.value = enabled;
  }

  static Duration getAnimationDuration() {
    return reducedMotion.value
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 300);
  }

  static Curve getAnimationCurve() {
    return reducedMotion.value
        ? Curves.linear
        : Curves.easeInOut;
  }

  static Color adjustColorForContrast(Color color) {
    if (!highContrastMode.value) return color;

    final luminance = color.computeLuminance();
    if (luminance > 0.5) {
      // For light colors, make them darker
      return Color.lerp(color, Colors.black, 0.3)!;
    } else {
      // For dark colors, make them lighter
      return Color.lerp(color, Colors.white, 0.3)!;
    }
  }

  static TextStyle adjustTextStyle(TextStyle style) {
    double finalScale = textScaleFactor.value;
    Color textColor = style.color ?? Colors.black;

    if (highContrastMode.value) {
      textColor = adjustColorForContrast(textColor);
    }

    return style.copyWith(
      fontSize: (style.fontSize ?? 14.0) * finalScale,
      color: textColor,
      letterSpacing: highContrastMode.value ? 0.5 : null,
    );
  }

  static void announceForScreenReader(BuildContext context, String message) {
    if (screenReaderEnabled.value) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  static Widget wrapWithSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      enabled: true,
      onTap: onTap,
      child: ExcludeSemantics(
        excluding: screenReaderEnabled.value,
        child: child,
      ),
    );
  }

  static Widget wrapForAccessibility(Widget child, {required String label}) {
    return Semantics(
      label: label,
      child: child,
    );
  }

  static Widget addKeyboardShortcut({
    required String label,
    required LogicalKeySet shortcut,
    required VoidCallback onInvoke,
    required Widget child,
  }) {
    return Shortcuts(
      shortcuts: {
        shortcut: VoidCallbackIntent(onInvoke),
      },
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: MergeSemantics(
          child: Semantics(
            label: '$label (${_getShortcutLabel(shortcut)})',
            child: child,
          ),
        ),
      ),
    );
  }

  static String _getShortcutLabel(LogicalKeySet shortcut) {
    return shortcut.keys
        .map((key) => key.keyLabel)
        .join('+')
        .replaceAll('Key', '');
  }

  static void addKeyboardShortcutOld({
    required LogicalKeySet keyCombination,
    required VoidCallback handler,
  }) {
    // Keyboard shortcut implementation
  }

  static BoxDecoration getHighContrastDecoration(BoxDecoration decoration) {
    if (!highContrastMode.value) return decoration;

    Color? adjustedColor = decoration.color != null
        ? adjustColorForContrast(decoration.color!)
        : null;

    Border? adjustedBorder = decoration.border != null
        ? Border.all(
            color: adjustColorForContrast(
              (decoration.border as Border).top.color,
            ),
            width: 2.0,
          )
        : null;

    return decoration.copyWith(
      color: adjustedColor,
      border: adjustedBorder,
    );
  }

  static ThemeData adjustThemeForAccessibility(ThemeData theme) {
    if (!highContrastMode.value) return theme;

    return theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: adjustColorForContrast(theme.textTheme.bodyLarge?.color ?? Colors.black),
        displayColor: adjustColorForContrast(theme.textTheme.displayLarge?.color ?? Colors.black),
      ),
      primaryColor: adjustColorForContrast(theme.primaryColor),
      scaffoldBackgroundColor: adjustColorForContrast(theme.scaffoldBackgroundColor),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: adjustColorForContrast(theme.appBarTheme.backgroundColor ?? theme.primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: adjustColorForContrast(theme.primaryColor),
          foregroundColor: adjustColorForContrast(theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}
