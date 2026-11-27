import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  /// Monospace style for coordinates.
  static TextStyle mono(BuildContext context, {double size = 14, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: context.colors.text);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryFg,
      secondary: c.simulated,
      onSecondary: Colors.white,
      // Selected/tonal states use the brand blue, never the coral "simulated" colour.
      secondaryContainer: c.primary.withValues(alpha: 0.14),
      onSecondaryContainer: c.primary,
      primaryContainer: c.primary.withValues(alpha: 0.14),
      onPrimaryContainer: c.primary,
      error: c.danger,
      onError: Colors.white,
      surface: c.bgElevated,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.bg,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48), shape: shape, textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), shape: shape, side: BorderSide(color: c.border)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(44, 44), shape: shape)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: c.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      ),
      cardTheme: CardThemeData(
        color: c.bgElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.border)),
      ),
      // Coral is reserved for "simulated location"; selection uses the brand primary.
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: c.border),
        selectedColor: c.primary.withValues(alpha: 0.14),
        checkmarkColor: c.primary,
        secondarySelectedColor: c.primary.withValues(alpha: 0.14),
        backgroundColor: c.bgElevated,
        labelStyle: TextStyle(color: c.text),
        secondaryLabelStyle: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgElevated,
        indicatorColor: c.primary.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgElevated,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1),
      listTileTheme: ListTileThemeData(shape: shape, iconColor: c.textMuted),
    );
  }
}
