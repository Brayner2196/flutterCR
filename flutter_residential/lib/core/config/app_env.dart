/// Configuración de ambiente — valores inyectados en tiempo de compilación
/// via --dart-define. NUNCA hardcodear URLs aquí.
///
/// Uso:
///   flutter run  --dart-define=API_BASE_URL=http://10.0.2.2:8080
///   flutter build apk --dart-define=API_BASE_URL=https://api.conjuntosCR.com
///
/// Ver Makefile en la raíz del proyecto para los comandos por ambiente.
library;

class AppEnv {
  AppEnv._();

  // ── URL base del backend ─────────────────────────────────────────────────
  /// Vacío por defecto: el assert de [validate] lo atrapa en release si falta.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // emulador Android local
  );

  // ── Nombre del ambiente (para logs/banners) ──────────────────────────────
  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  // ── Helpers ──────────────────────────────────────────────────────────────
  static bool get isDev     => name == 'dev';
  static bool get isStaging => name == 'staging';
  static bool get isProd    => name == 'prod';

  /// Llama esto en main() antes de runApp().
  /// Falla rápido si alguien intenta hacer un build de release sin definir la URL.
  static void validate() {
    if (baseUrl.isEmpty) {
      throw StateError('API_BASE_URL no definida. Usa --dart-define=API_BASE_URL=<url>.');
    }
    final esLocal = baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2');
    if (isProd && esLocal) {
      throw StateError('APP_ENV=prod con API_BASE_URL local ($baseUrl). Revisa el build.');
    }
    if (isProd && baseUrl.startsWith('http://')) {
      throw StateError('APP_ENV=prod exige https. Actual: $baseUrl');
    }
  }
}
