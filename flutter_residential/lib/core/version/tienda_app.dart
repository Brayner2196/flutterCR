import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ficha de la app en su tienda: el respaldo cuando la actualización nativa
/// no aplica (instalada fuera de Play, otro track de pruebas, iOS, caché de
/// Play que todavía no ve la versión nueva).
///
/// Vive aparte del provider y de la UI para que la pantalla de bloqueo y el
/// banner usen exactamente la misma regla, y para que la resolución de la URL
/// ([url]) se pueda probar sin abrir nada.
///
/// No importa `dart:io`: se puede usar desde cualquier plataforma sin pasar
/// por el import condicional de `actualizador.dart`.
class TiendaApp {
  TiendaApp._();

  /// Igual al `applicationId` de `android/app/build.gradle`. Si cambia allá,
  /// cambia acá.
  static const String _androidId = 'com.flutter_residential.flutter_residential';

  /// La URL del backend manda. Si no viene, en Android se arma la de Play
  /// para que el usuario nunca quede encerrado por un dato faltante en la BD.
  ///
  /// Se usa `https://play.google.com/...` y no `market://`: Android la abre en
  /// la app de Play igual, y el `<queries>` de `https` ya está en el manifest.
  static String? url(String? desdeBackend) {
    final b = desdeBackend?.trim();
    if (b != null && b.isNotEmpty) return b;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'https://play.google.com/store/apps/details?id=$_androidId';
    }
    return null; // iOS / web sin URL configurada: no hay a dónde mandar.
  }

  /// Abre la tienda fuera de la app. Nunca lanza.
  static Future<bool> abrir(String? desdeBackend) async {
    final uri = Uri.tryParse(url(desdeBackend) ?? '');
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[TiendaApp] no se pudo abrir $uri: $e');
      return false;
    }
  }
}
