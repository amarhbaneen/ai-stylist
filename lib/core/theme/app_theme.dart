import 'package:material_ui/material_ui.dart';

/// Neutral, temporary design system (no third-party branding; CLAUDE.md #7).
abstract final class AppTheme {
  /// Muted slate seed; Material 3 derives an accessible tonal palette from it.
  static const _seed = Color(0xFF4F5D75);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      // Minimum 48dp touch targets for accessibility.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
