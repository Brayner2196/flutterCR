import 'package:flutter/material.dart';
import '../../../core/storage/onboarding_storage.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool? _haVistoOnboarding;

  AppProvider() {
    _cargarOnboarding();
  }

  ThemeMode get themeMode => _themeMode;

  /// `null` mientras se lee shared_preferences; luego `true`/`false`.
  /// El SplashScreen lo usa para decidir si mostrar onboarding o login.
  bool? get haVistoOnboarding => _haVistoOnboarding;

  /// Brillo efectivo actual. Resuelve [ThemeMode.system] al brillo real del
  /// dispositivo para que el toggle refleje lo que el usuario ve en pantalla.
  bool esOscuro(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  /// Alterna el tema partiendo del brillo efectivo actual (no del modo crudo),
  /// así el primer toque siempre produce un cambio visible.
  void toggleTheme(BuildContext context) {
    _themeMode = esOscuro(context) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> _cargarOnboarding() async {
    _haVistoOnboarding = await OnboardingStorage.haVistoOnboarding();
    notifyListeners();
  }

  Future<void> completarOnboarding() async {
    await OnboardingStorage.marcarComoVisto();
    _haVistoOnboarding = true;
    notifyListeners();
  }
}
