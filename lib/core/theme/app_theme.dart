import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Editorial, neutral design system: paper and ink, one accent, a serif for
/// titles and a sans for text, one radius, a 4-point spacing scale
/// (DECISIONS D-42). No third-party branding (CLAUDE.md #7).
abstract final class AppTheme {
  static ThemeData light() => _build(_light);

  static ThemeData dark() => _build(_dark);

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.accent,
    onPrimary: Colors.white,
    primaryContainer: Palette.accentSoft,
    onPrimaryContainer: Palette.accent,
    secondary: Palette.ink,
    onSecondary: Palette.paper,
    secondaryContainer: Palette.paperSunken,
    onSecondaryContainer: Palette.ink,
    tertiary: Palette.accent,
    onTertiary: Colors.white,
    error: Palette.error,
    onError: Colors.white,
    errorContainer: Palette.errorSoft,
    onErrorContainer: Palette.error,
    surface: Palette.paper,
    onSurface: Palette.ink,
    onSurfaceVariant: Palette.inkMuted,
    surfaceContainerLowest: Palette.paperRaised,
    surfaceContainerLow: Palette.paperRaised,
    surfaceContainer: Palette.paper,
    surfaceContainerHigh: Palette.paperSunken,
    surfaceContainerHighest: Palette.paperSunken,
    outline: Palette.inkMuted,
    outlineVariant: Palette.hairline,
    inverseSurface: Palette.ink,
    onInverseSurface: Palette.paper,
    inversePrimary: Palette.accentNight,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Palette.accentNight,
    onPrimary: Palette.onAccentNight,
    primaryContainer: Palette.accentSoftNight,
    onPrimaryContainer: Palette.accentNight,
    secondary: Palette.chalk,
    onSecondary: Palette.night,
    secondaryContainer: Palette.nightSunken,
    onSecondaryContainer: Palette.chalk,
    tertiary: Palette.accentNight,
    onTertiary: Palette.onAccentNight,
    error: Palette.errorNight,
    onError: Palette.night,
    errorContainer: Palette.errorSoftNight,
    onErrorContainer: Palette.errorNight,
    surface: Palette.night,
    onSurface: Palette.chalk,
    onSurfaceVariant: Palette.chalkMuted,
    surfaceContainerLowest: Palette.night,
    surfaceContainerLow: Palette.nightRaised,
    surfaceContainer: Palette.nightRaised,
    surfaceContainerHigh: Palette.nightSunken,
    surfaceContainerHighest: Palette.nightSunken,
    outline: Palette.chalkMuted,
    outlineVariant: Palette.nightHairline,
    inverseSurface: Palette.chalk,
    onInverseSurface: Palette.night,
    inversePrimary: Palette.accent,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static TextTheme _text(ColorScheme c) {
    TextStyle display(double size, double height) => TextStyle(
      fontFamily: Fonts.display,
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      color: c.onSurface,
    );
    TextStyle text(
      double size,
      FontWeight weight, {
      double height = 1.4,
      double spacing = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: Fonts.text,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color ?? c.onSurface,
    );
    return TextTheme(
      displayLarge: display(56, 1.05),
      displayMedium: display(44, 1.08),
      displaySmall: display(36, 1.1),
      headlineLarge: display(34, 1.12),
      headlineMedium: display(30, 1.15),
      headlineSmall: display(26, 1.2),
      titleLarge: text(19, FontWeight.w600, height: 1.3, spacing: -0.2),
      titleMedium: text(16, FontWeight.w600, height: 1.35, spacing: -0.1),
      titleSmall: text(14, FontWeight.w600, height: 1.35),
      bodyLarge: text(16, FontWeight.w400, height: 1.5),
      bodyMedium: text(14, FontWeight.w400, height: 1.5),
      bodySmall: text(12.5, FontWeight.w400, color: c.onSurfaceVariant),
      labelLarge: text(14, FontWeight.w500, spacing: 0.1),
      labelMedium: text(12.5, FontWeight.w500, spacing: 0.2),
      // Small caps-like overline for section labels.
      labelSmall: text(
        11,
        FontWeight.w600,
        spacing: 1.1,
        color: c.onSurfaceVariant,
      ),
    );
  }

  static ThemeData _build(ColorScheme c) {
    final t = _text(c);
    final hairline = BorderSide(color: c.outlineVariant);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: Space.xl,
      vertical: Space.md,
    );
    const buttonSize = Size(64, 52);
    final buttonText = t.labelLarge!.copyWith(fontWeight: FontWeight.w600);

    return ThemeData(
      colorScheme: c,
      fontFamily: Fonts.text,
      textTheme: t,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      visualDensity: VisualDensity.standard,
      // Minimum 48dp touch targets for accessibility.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: c.outlineVariant,
        thickness: 1,
        space: Space.xl,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: Space.page,
        titleTextStyle: t.headlineMedium,
        toolbarHeight: 64,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => t.labelMedium!.copyWith(
            color: s.contains(WidgetState.selected)
                ? c.onSurface
                : c.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: c.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.all, side: hairline),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: Radii.shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: Radii.shape,
          side: BorderSide(color: c.onSurface),
          foregroundColor: c.onSurface,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: Radii.shape,
          foregroundColor: c.onSurface,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: Radii.shape),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.onSurface,
        foregroundColor: c.surface,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: Radii.shape,
        extendedTextStyle: buttonText,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: Radii.shape,
          side: hairline,
          selectedBackgroundColor: c.onSurface,
          selectedForegroundColor: c.surface,
          textStyle: t.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: Radii.shape,
        side: hairline,
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onSurface : c.surface,
        ),
        checkmarkColor: c.surface,
        showCheckmark: false,
        // Chips resolve the label colour from the style's colour as a
        // state colour, so the state lives there.
        labelStyle: t.labelLarge!.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.surface : c.onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: c.onSurfaceVariant, size: 18),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: Radii.all,
          borderSide: hairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.all,
          borderSide: hairline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.all,
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.transparent : c.outline,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.page),
        shape: Radii.shape,
        titleTextStyle: t.bodyLarge,
        subtitleTextStyle: t.bodySmall,
        iconColor: c.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: t.bodyMedium!.copyWith(color: c.onInverseSurface),
        actionTextColor: c.inversePrimary,
        shape: Radii.shape,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: Radii.shape,
        titleTextStyle: t.headlineSmall,
        contentTextStyle: t.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.value),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.outlineVariant,
        circularTrackColor: Colors.transparent,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.primary,
        textColor: c.onPrimary,
      ),
      // Page transitions: platform defaults (predictive back on Android,
      // Cupertino on iOS).
    );
  }
}
