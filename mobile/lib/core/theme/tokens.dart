import 'package:flutter/material.dart';

/// Design tokens shared with web (`web/packages/ui/src/tokens.css`). Keep values in sync.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bgElevated,
    required this.surfaceGlass,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.primaryFg,
    required this.simulated,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bg;
  final Color bgElevated;
  final Color surfaceGlass;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color primaryFg;

  /// Coral: always means "simulated location".
  final Color simulated;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = AppColors(
    bg: Color(0xFFF4F6F9),
    bgElevated: Color(0xFFFFFFFF),
    surfaceGlass: Color(0xB8FFFFFF),
    border: Color(0x140F172A),
    text: Color(0xFF0B1220),
    textMuted: Color(0xFF5B6474),
    primary: Color(0xFF3457F5),
    primaryFg: Color(0xFFFFFFFF),
    simulated: Color(0xFFF2542D),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
  );

  static const dark = AppColors(
    bg: Color(0xFF07090D),
    bgElevated: Color(0xFF0F131A),
    surfaceGlass: Color(0xAD141820),
    border: Color(0x14FFFFFF),
    text: Color(0xFFE8ECF2),
    textMuted: Color(0xFF8E97A8),
    primary: Color(0xFF7088FF),
    primaryFg: Color(0xFF0A0F1F),
    simulated: Color(0xFFFF7A5C),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      bgElevated: l(bgElevated, other.bgElevated),
      surfaceGlass: l(surfaceGlass, other.surfaceGlass),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      primary: l(primary, other.primary),
      primaryFg: l(primaryFg, other.primaryFg),
      simulated: l(simulated, other.simulated),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const curve = Cubic(0.2, 0.8, 0.2, 1);
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
