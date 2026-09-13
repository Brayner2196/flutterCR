import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'app_version.dart';
import 'resultado_actualizacion.dart';

/// Actualización en web.
///
/// Aquí no hay nada que descargar: el service worker que genera Flutter ya trae
/// la versión nueva en segundo plano al abrir la página. Lo único que falta es
/// aplicarla, y eso es un `reload`.
///
/// Que esto funcione depende de los encabezados de caché de Firebase Hosting:
/// `index.html`, `flutter_service_worker.js` y `version.json` tienen que salir
/// con `no-cache`. Si alguno queda con caché larga, el navegador sigue
/// sirviendo lo viejo y el recargar no cambia nada. En `firebase.json` ya está
/// puesto para `js|json|html|wasm|css`.
class Actualizador {
  Actualizador._();

  /// Comprueba que el hosting ya esté sirviendo una versión posterior.
  ///
  /// Sin esta verificación aparecería un caso desagradable: el backend anuncia
  /// una versión nueva pero el deploy a Hosting todavía no se hizo, el usuario
  /// recarga, vuelve a cargar lo mismo, y el aviso reaparece. Un bucle que
  /// desde afuera parece que la app está rota.
  static Future<ResultadoActualizacion> descargarEnSegundoPlano() async {
    final servido = await _buildServido();

    // No se pudo leer version.json: se asume que sí hay algo nuevo y se deja
    // que el usuario recargue. Es preferible una recarga de más que dejarlo
    // atascado en una versión vieja.
    if (servido == null) return ResultadoActualizacion.listaParaAplicar;

    return servido > AppVersion.build
        ? ResultadoActualizacion.listaParaAplicar
        : ResultadoActualizacion.sinNovedad;
  }

  /// Recarga la página. El service worker ya tiene los archivos nuevos, así que
  /// es casi instantáneo y no depende de la red.
  static Future<ResultadoActualizacion> completar() async {
    web.window.location.reload();
    return ResultadoActualizacion.aplicada;
  }

  /// En web no hay diferencia entre obligatoria y sugerida: ambas terminan en
  /// una recarga. Lo que cambia es la pantalla que la pide.
  static Future<ResultadoActualizacion> actualizarBloqueando() => completar();

  // ─── Interno ─────────────────────────────────────────────────────────────

  /// Lee el `version.json` que Flutter genera en cada build web.
  ///
  /// Se le agrega una marca de tiempo a la URL además del encabezado: algunos
  /// navegadores ignoran `no-cache` en peticiones desde un service worker
  /// activo, y sin eso se leería la versión vieja precisamente en el momento
  /// en que hay que detectar la nueva.
  static Future<int?> _buildServido() async {
    try {
      final uri = Uri.parse('version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http
          .get(uri, headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return int.tryParse(json['build_number']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
