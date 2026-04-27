import 'package:flutter/material.dart';
import '../core/storage/onboarding_storage.dart';

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

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
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
