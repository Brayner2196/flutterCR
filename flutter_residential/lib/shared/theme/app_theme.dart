import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const warning     = Color.fromRGBO(154, 107, 0, 1);
  static const warningSoft = Color.fromRGBO(255, 245, 215, 1);

  // Quick access cards
  static const bgBlue  = Color.fromRGBO(230, 247, 255, 1);
  static const bgBlueModDark = Color.fromRGBO(22, 34, 43, 1);
  static const blue    = Color.fromRGBO(0,   95,  143, 1);
  static const blueModDark   = Color.fromRGBO(116, 185, 228, 1);

  static const bgYellow = Color.fromRGBO(255, 251, 230, 1);
  static const bgYellowModDark = Color.fromRGBO(40, 33, 17, 1);
  static const yellow   = Color.fromRGBO(140, 109, 0,   1);
  static const yellowModDark   = Color.fromRGBO(230, 188, 87, 1);

  static const bgGreen = Color.fromRGBO(230, 255, 243, 1);
  static const bgGreenModDark = Color.fromRGBO(20, 37, 25, 1);
  static const green   = Color.fromRGBO(0,   105, 74,  1);
  static const greenModDark   = Color.fromRGBO(95, 206, 146, 1);

  static const bgPurple = Color.fromRGBO(249, 230, 255, 1);
  static const bgPurpleModDark = Color.fromRGBO(36, 26, 49, 1);
  static const purple   = Color.fromRGBO(110, 40,  145, 1);
  static const purpleModDark   = Color.fromRGBO(196, 145, 227, 1);

  static const bgTeal  = Color.fromRGBO(224, 247, 244, 1);
  static const bgTealModDark = Color.fromRGBO(16, 36, 31, 1);
  static const teal    = Color.fromRGBO(0,   105, 92,  1);
  static const tealModDark   = Color.fromRGBO(79, 201, 189, 1);

  static const bgOrange = Color.fromRGBO(255, 237, 224, 1);
  static const bgOrangeModDark = Color.fromRGBO(42, 28, 18, 1);
  static const orange   = Color.fromRGBO(180, 80,  0,   1);
  static const orangeModDark   = Color.fromRGBO(232, 158, 99, 1);

  static const bgCoral = Color.fromRGBO(255, 234, 228, 1);
  static const bgCoralModDark = Color.fromRGBO(44, 24, 21, 1);
  static const coral = Color.fromRGBO(184, 68, 51, 1);
  static const coralModDark = Color.fromRGBO(235, 125, 116, 1);

  static const bgSlate = Color.fromRGBO(236, 239, 243, 1);
  static const bgSlateModDark = Color.fromRGBO(27, 32, 41, 1);
  static const slate = Color.fromRGBO(67, 82, 100, 1);
  static const slateModDark = Color.fromRGBO(147, 166, 188, 1);

  static const bgLime = Color.fromRGBO(241, 247, 222, 1);
  static const bgLimeModDark = Color.fromRGBO(32, 38, 17, 1);
  static const lime = Color.fromRGBO(85, 107, 14, 1);
  static const limeModDark = Color.fromRGBO(174, 203, 91, 1);

  static const bgCyan = Color.fromRGBO(224, 246, 251, 1);
  static const bgCyanModDark = Color.fromRGBO(15, 37, 44, 1);
  static const cyan = Color.fromRGBO(0, 105, 126, 1);
  static const cyanModDark = Color.fromRGBO(70, 195, 222, 1);
}

/// Espaciado consistente en toda la app.
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

/// Radios de borde consistentes en toda la app.
class AppRadius {
  static const double sm    = 8;
  static const double md    = 12;
  static const double lg    = 16;
  static const double xl    = 20;
  static const double xxl   = 28;
  static const double card  = 14;
  static const double btn   = 14;
  static const double input = 10;
}

class PaletteQuickAccessCard {
  final Color bg;
  final Color fg;

  const PaletteQuickAccessCard(this.bg, this.fg);

  static PaletteQuickAccessCard resolve(Color lightBg, Color lightFg, bool isDark) {
    if (!isDark) return PaletteQuickAccessCard(lightBg, lightFg);
    return _darkByBg[lightBg.toARGB32()] ??
        PaletteQuickAccessCard(AppColors.surfaceDark, lightFg); // fallback neutro
  }

  static final Map<int, PaletteQuickAccessCard> _darkByBg = {
    AppColors.bgBlue.toARGB32():   const PaletteQuickAccessCard(AppColors.bgBlueModDark,   AppColors.blueModDark),
    AppColors.bgOrange.toARGB32(): const PaletteQuickAccessCard(AppColors.bgOrangeModDark, AppColors.orangeModDark),
    AppColors.bgPurple.toARGB32(): const PaletteQuickAccessCard(AppColors.bgPurpleModDark, AppColors.purpleModDark),
    AppColors.bgYellow.toARGB32(): const PaletteQuickAccessCard(AppColors.bgYellowModDark, AppColors.yellowModDark),
    AppColors.bgGreen.toARGB32():  const PaletteQuickAccessCard(AppColors.bgGreenModDark,  AppColors.greenModDark),
    AppColors.bgCoral.toARGB32():  const PaletteQuickAccessCard(AppColors.bgCoralModDark,  AppColors.coralModDark),
    AppColors.bgTeal.toARGB32():   const PaletteQuickAccessCard(AppColors.bgTealModDark, AppColors.tealModDark),
    AppColors.bgSlate.toARGB32():  const PaletteQuickAccessCard(AppColors.bgSlateModDark, AppColors.slateModDark),
    AppColors.bgLime.toARGB32():   const PaletteQuickAccessCard(AppColors.bgLimeModDark,  AppColors.limeModDark),
    AppColors.bgCyan.toARGB32():   const PaletteQuickAccessCard(AppColors.bgCyanModDark,  AppColors.cyanModDark),
  };

}

/// Tema Material 3 con paleta neutral + acento azul profundo.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  final primaryColor = isDark ? AppColors.textHiDark : AppColors.blue;
  final bg           = isDark ? AppColors.bgDark      : AppColors.bgLight;
  final surface      = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final textHi       = isDark ? AppColors.textHiDark  : AppColors.textHiLight;
  final textMid      = isDark ? AppColors.textMidDark : AppColors.textMidLight;
  final border       = isDark ? AppColors.borderDark  : AppColors.borderLight;

  final cs = ColorScheme(
    brightness: brightness,
    primary:            primaryColor,
    onPrimary:          isDark ? AppColors.textHiDark : AppColors.surfaceAltDark,
    primaryContainer:   isDark ? AppColors.surfaceAltDark : AppColors.bgBlue,
    onPrimaryContainer: isDark ? AppColors.blue    : AppColors.bgLight,
    secondary:          isDark ? AppColors.surfaceAltDark : AppColors.okSoft,
    onSecondary:        isDark ? AppColors.textMidDark   : AppColors.ok,
    error:              AppColors.danger,
    onError:            Colors.white,
    surface:            surface,
    onSurface:          textHi,
    surfaceContainerHighest: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
    outline:            border,
    outlineVariant:     isDark ? AppColors.hairlineDark  : AppColors.hairlineLight,
    onSurfaceVariant:   textMid,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.btn),
  );

  final textTheme = _buildTextTheme(textHi);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: bg,
    fontFamily: 'GoogleSans',
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg,
      foregroundColor: cs.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: cs.onSurface),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: cs.outline, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      labelStyle: TextStyle(color: textMid),
      hintStyle: TextStyle(color: textMid.withValues(alpha: 0.6)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
        textStyle: const TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: buttonShape,
        textStyle: const TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        minimumSize: const Size(0, 44),
        shape: buttonShape,
        textStyle: const TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: isDark ? AppColors.hairlineDark : AppColors.hairlineLight,
      thickness: 1,
      space: 1,
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      tileColor: Colors.transparent,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: isDark ? AppColors.surfaceAltDark : AppColors.bgBlue,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryColor, size: 22);
        }
        return IconThemeData(color: textMid, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          );
        }
        return TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMid,
        );
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.textHiLight,
      contentTextStyle: TextStyle(
        fontFamily: 'GoogleSans',
        color: isDark ? AppColors.textHiDark : AppColors.bgLight,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: isDark ? AppColors.textHiDark : AppColors.textHiLight,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.textMidDark : AppColors.textMidLight,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      elevation: 8,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark ? AppColors.textLoDark : AppColors.textLoLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return isDark ? AppColors.surfaceAltDark : AppColors.borderLight;
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: border, width: 1.5),
    ),
  );
}

TextTheme _buildTextTheme(Color baseColor) {
  return TextTheme(
    displayLarge:   _ts(57, FontWeight.w400, baseColor, -0.25),
    displayMedium:  _ts(45, FontWeight.w400, baseColor, 0),
    displaySmall:   _ts(36, FontWeight.w400, baseColor, 0),
    headlineLarge:  _ts(32, FontWeight.w700, baseColor, 0),
    headlineMedium: _ts(28, FontWeight.w700, baseColor, -0.25),
    headlineSmall:  _ts(24, FontWeight.w700, baseColor, 0),
    titleLarge:     _ts(22, FontWeight.w600, baseColor, 0),
    titleMedium:    _ts(16, FontWeight.w600, baseColor, 0.15),
    titleSmall:     _ts(14, FontWeight.w600, baseColor, 0.1),
    bodyLarge:      _ts(16, FontWeight.w400, baseColor, 0.5),
    bodyMedium:     _ts(14, FontWeight.w400, baseColor, 0.25),
    bodySmall:      _ts(12, FontWeight.w400, baseColor, 0.4),
    labelLarge:     _ts(14, FontWeight.w500, baseColor, 0.1),
    labelMedium:    _ts(12, FontWeight.w500, baseColor, 0.5),
    labelSmall:     _ts(11, FontWeight.w500, baseColor, 0.5),
  );
}

TextStyle _ts(double size, FontWeight weight, Color color, double spacing) =>
    TextStyle(
      fontFamily: 'GoogleSans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
