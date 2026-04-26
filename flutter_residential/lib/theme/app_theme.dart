import 'package:flutter/material.dart';

/// Paleta y tokens de diseño — versión Flutter del rediseño V1.
/// Neutral cálido + acento azul profundo (oklch-inspired).
class AppColors {
  // Light
  static const bgLight         = Color.fromRGBO(255, 255, 255, 1);
  static const surfaceLight    = Color.fromRGBO(249, 249, 249, 1);
  static const surfaceAltLight = Color.fromRGBO(235, 241, 255, 1);
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
  static const dangerSoft  = Color.fromRGBO(251, 234, 234, 1);
  static const neutralSoft = Color.fromRGBO(236, 236, 234, 1);

  // Quick access cards
  static const bgBlue  = Color.fromRGBO(230, 247, 255, 1);
  static const blue    = Color.fromRGBO(0,   95,  143, 1);

  static const bgYellow = Color.fromRGBO(255, 251, 230, 1);
  static const yellow   = Color.fromRGBO(140, 109, 0,   1);

  static const bgGreen = Color.fromRGBO(230, 255, 243, 1);
  static const green   = Color.fromRGBO(0,   105, 74,  1);

  static const bgPurple = Color.fromRGBO(249, 230, 255, 1);
  static const purple   = Color.fromRGBO(110, 40,  145, 1);
}

/// Tema Material 3 con paleta neutral + acento azul profundo.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  // Acento principal: azul en light, casi-blanco en dark
  final primaryColor = isDark ? AppColors.textHiDark : AppColors.blue;

  final cs = ColorScheme(
    brightness: brightness,
    primary:            primaryColor,
    onPrimary:          Colors.white,
    primaryContainer:   isDark ? AppColors.surfaceAltDark : AppColors.bgBlue,
    onPrimaryContainer: isDark ? AppColors.textHiDark    : AppColors.blue,
    secondary:          isDark ? AppColors.surfaceAltDark : AppColors.okSoft,
    onSecondary:        isDark ? AppColors.textMidDark   : AppColors.ok,
    error:              AppColors.danger,
    onError:            Colors.white,
    surface:            isDark ? AppColors.surfaceDark   : AppColors.surfaceLight,
    onSurface:          isDark ? AppColors.textHiDark    : AppColors.textHiLight,
    surfaceContainerHighest:
                        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
    outline:            isDark ? AppColors.borderDark    : AppColors.borderLight,
    outlineVariant:     isDark ? AppColors.hairlineDark  : AppColors.hairlineLight,
    onSurfaceVariant:   isDark ? AppColors.textMidDark   : AppColors.textMidLight,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    fontFamily: 'GoogleSans',
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
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        minimumSize: const Size(0, 44),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
    ),
  );
}
