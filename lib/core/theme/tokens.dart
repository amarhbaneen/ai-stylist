import 'package:material_ui/material_ui.dart';

/// Design tokens: the only spacing, radius, colour and motion values the
/// UI uses (DECISIONS D-42). Screens read them from here or from the theme;
/// raw numbers in widgets are a bug.

/// Spacing scale (4-point).
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page margin.
  static const page = xl;
}

/// The one corner radius, used for every rounded shape.
abstract final class Radii {
  static const value = 8.0;
  static const all = BorderRadius.all(Radius.circular(value));
  static const shape = RoundedRectangleBorder(borderRadius: all);
}

/// Motion: short, purposeful, and off when the system asks for less.
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const long = Duration(milliseconds: 400);

  /// Things arriving on screen.
  static const enter = Curves.easeOutCubic;

  /// Things changing in place.
  static const standard = Curves.easeInOutCubic;

  /// [d], or zero when the user turned animations off.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Palette: warm paper, ink, and one accent (bottle green). Every text
/// pair meets WCAG AA; most meet AAA.
abstract final class Palette {
  // Light
  static const paper = Color(0xFFF6F4EF);
  static const paperRaised = Color(0xFFFFFFFF);
  static const paperSunken = Color(0xFFEDEAE3);
  static const ink = Color(0xFF171614);
  static const inkMuted = Color(0xFF6B665D);
  static const hairline = Color(0xFFDDD8CF);
  static const accent = Color(0xFF1F4D3A);
  static const accentSoft = Color(0xFFDCE8E0);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFF9DEDC);

  // Dark
  static const night = Color(0xFF141312);
  static const nightRaised = Color(0xFF1D1C1A);
  static const nightSunken = Color(0xFF242320);
  static const chalk = Color(0xFFECE8E1);
  static const chalkMuted = Color(0xFF9A958C);
  static const nightHairline = Color(0xFF34322E);
  static const accentNight = Color(0xFF8CC2A6);
  static const onAccentNight = Color(0xFF0F2A1F);
  static const accentSoftNight = Color(0xFF233B30);
  static const errorNight = Color(0xFFF2B8B5);
  static const errorSoftNight = Color(0xFF5C1A16);
}

/// Font families bundled in `assets/fonts/` (SIL OFL 1.1). Nothing is
/// downloaded at runtime.
abstract final class Fonts {
  /// Display serif for titles.
  static const display = 'InstrumentSerif';

  /// Text sans for everything else.
  static const text = 'Geist';
}
