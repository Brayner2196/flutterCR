import 'package:flutter/material.dart';

/// Paleta y tokens de diseño — versión Flutter del rediseño V1.
/// Neutral cálido + acento violeta low-chroma (inspirado en oklch).
class AppColors {
  // Light
  static const bgLight         = Color(0xFFF7F6F4);
  static const surfaceLight    = Color(0xFFFFFFFF);
  static const surfaceAltLight = Color(0xFFF1EFEC);
  static const borderLight     = Color(0xFFE6E3DD);
  static const hairlineLight   = Color(0xFFEDEDEA);
  static const textHiLight     = Color(0xFF1A1917);
  static const textMidLight    = Color(0xFF57544D);
  static const textLoLight     = Color(0xFF8A867D);

  // Dark
  static const bgDark         = Color(0xFF141311);
  static const surfaceDark    = Color(0xFF1C1B19);
  static const surfaceAltDark = Color(0xFF242220);
  static const borderDark     = Color(0xFF2E2C29);
  static const hairlineDark   = Color(0xFF252320);
  static const textHiDark     = Color(0xFFF2EFE9);
  static const textMidDark    = Color(0xFFA8A49C);
  static const textLoDark     = Color(0xFF6F6C65);

  // Acento (violeta low-chroma)
  static const accent      = Color(0xFF6B5ECF);
  static const accentSoft  = Color(0xFFEBE8FA);
  static const accentText  = Color(0xFF4A3FB0);

  // Estados
  static const ok          = Color(0xFF3F7A4F);
  static const okSoft      = Color(0xFFE4EDE3);
  static const danger      = Color(0xFFA34A4A);
  static const neutralSoft = Color(0xFFECECEA);
}

/// Tema Material 3 actualizado con paleta neutral.
/// Reemplaza el ThemeData en main.dart.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme(
    brightness: brightness,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.accentText,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    onSurface: isDark ? AppColors.textHiDark : AppColors.textHiLight,
    surfaceContainerHighest:
        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
    outline: isDark ? AppColors.borderDark : AppColors.borderLight,
    outlineVariant: isDark ? AppColors.hairlineDark : AppColors.hairlineLight,
    onSurfaceVariant:
        isDark ? AppColors.textMidDark : AppColors.textMidLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      foregroundColor: cs.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: cs.onSurface,
        foregroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}
