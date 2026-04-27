import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local para el flujo de onboarding.
/// Solo se muestra en la primera apertura de la app.
class OnboardingStorage {
  static const _keyOnboardingSeen = 'onboarding_seen';

  static Future<bool> haVistoOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  static Future<void> marcarComoVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  static Future<void> reiniciar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingSeen);
  }
}
