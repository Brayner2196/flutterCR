import 'package:flutter/material.dart';

/// Paleta y tokens de diseño — versión Flutter del rediseño V1.
/// Neutral cálido + acento violeta low-chroma (inspirado en oklch).
class AppColors {
  // Light
  static const bgLight         = Color.fromRGBO(255, 255, 255, 1);
  static const surfaceLight    = Color.fromRGBO(249, 249, 249, 1.2);
  static const surfaceAltLight = Color.fromRGBO(180, 197, 255, 1);
  static const borderLight     = Color.fromRGBO(224, 227, 229, 1);
  static const hairlineLight   = Color.fromRGBO(238, 240, 242, 1);
  static const textHiLight     = Color.fromRGBO(25, 28, 30, 1);
  static const textMidLight    = Color.fromRGBO(81, 95, 116, 1);
  static const textLoLight     = Color.fromRGBO(115, 120, 126, 1);

  // Dark
  static const bgDark         = Color.fromRGBO(20, 19, 17, 1);
  static const surfaceDark    = Color.fromRGBO(28, 27, 25, 1);
  static const surfaceAltDark = Color.fromRGBO(36, 34, 32, 1);
  static const borderDark     = Color.fromRGBO(46, 44, 41, 1);
  static const hairlineDark   = Color.fromRGBO(37, 35, 32, 1);
  static const textHiDark     = Color.fromRGBO(242, 239, 233, 1);
  static const textMidDark    = Color.fromRGBO(168, 164, 156, 1);
  static const textLoDark     = Color.fromRGBO(111, 108, 101, 1);

  // Estados

  static const ok          = Color.fromRGBO(63, 122, 79, 1);
  static const okSoft      = Color.fromRGBO(228, 237, 227, 1);
  static const danger      = Color.fromRGBO(163, 74, 74, 1);
  static const neutralSoft = Color.fromRGBO(236, 236, 234, 1);

  // colors quick access cards
  static const bgBlue = Color.fromRGBO(230, 247, 255, 1);
  static const blue = Color.fromRGBO(0, 95, 143, 1);

  static const bgYellow = Color.fromRGBO(255, 251, 230, 1);
  static const yellow = Color.fromRGBO(140,109,0, 1);

}

/// Tema Material 3 actualizado con paleta neutral.
/// Reemplaza el ThemeData en main.dart.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme(
    brightness: brightness,
    primary: isDark ?  AppColors.bgDark : AppColors.bgLight,
    onPrimary: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,

    primaryContainer: AppColors.ok,
    onPrimaryContainer: AppColors.danger,
    secondary: AppColors.okSoft,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    onSurface: isDark ? AppColors.textHiDark : AppColors.textHiLight,
    surfaceContainerHighest: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
    outline: isDark ? AppColors.borderDark : AppColors.borderLight,
    outlineVariant: isDark ? AppColors.hairlineDark : AppColors.hairlineLight,
    onSurfaceVariant: isDark ? AppColors.textMidDark : AppColors.textMidLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    fontFamily: 'Poppins',
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
