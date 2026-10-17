import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'resultado_actualizacion.dart';

/// Actualización en Android mediante In-App Updates de Google Play.
///
/// Se usa el mecanismo de Play y no una descarga propia del APK porque una
/// instalación manual exige el permiso de "instalar apps desconocidas", saca a
/// la app del canal de actualizaciones de la tienda y puede costar una sanción
/// en Play. Play hace lo mismo, mejor, y ya está construido.
///
/// Los dos modos:
///  - **flexible**: descarga en segundo plano mientras el usuario sigue usando
///    la app. Es el que corresponde a una actualización sugerida.
///  - **immediate**: pantalla completa de Google que bloquea hasta terminar.
///    Solo para la actualización obligatoria.
///
/// En iOS no existe equivalente: `App Store` no permite actualizar desde
/// dentro. Ahí las funciones devuelven [ResultadoActualizacion.noDisponible] y
/// la UI cae al enlace de la tienda.
class Actualizador {
  Actualizador._();


  /// Descarga en segundo plano. No bloquea la app.
  ///
  /// Devuelve [ResultadoActualizacion.listaParaAplicar] cuando la descarga
  /// terminó: ahí la UI ofrece el botón de reiniciar. No se instala sola —
  /// `completar()` reinicia la app, y hacerlo en medio de un pago sería
  /// exactamente el peor momento posible.
  static Future<ResultadoActualizacion> descargarEnSegundoPlano() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return ResultadoActualizacion.sinNovedad;
      }
      if (!info.flexibleUpdateAllowed) {
        return ResultadoActualizacion.noDisponible;
      }

      final resultado = await InAppUpdate.startFlexibleUpdate();
      return resultado == AppUpdateResult.success
          ? ResultadoActualizacion.listaParaAplicar
          : ResultadoActualizacion.canceladaPorUsuario;
    } catch (e) {
      debugPrint('[Actualizador] startFlexibleUpdate: $e');
      return ResultadoActualizacion.noDisponible;
    }
  }

  /// Instala lo descargado y reinicia la app. Solo tras `listaParaAplicar`.
  static Future<ResultadoActualizacion> completar() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return ResultadoActualizacion.aplicada;
    } catch (e) {
      debugPrint('[Actualizador] completeFlexibleUpdate: $e');
      return ResultadoActualizacion.fallo;
    }
  }

  /// Obligatoria: solo PREGUNTA a Play si puede hacer la actualización
  /// inmediata. No abre nada; la pantalla de Play se abre cuando el usuario
  /// pulsa "Actualizar ahora" (`actualizarBloqueando`).
  ///
  /// El backend ya dijo que hay una versión nueva. Si Play no la ofrece aquí
  /// (app instalada fuera de Play, otro track de pruebas, caché de Play), la
  /// única salida es la tienda: por eso devuelve `noDisponible` y no
  /// `sinNovedad`, que dejaría al usuario sin botón para salir.
  static Future<ResultadoActualizacion> prepararObligatoria() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return _puedeInmediato(info)
          ? ResultadoActualizacion.listaParaAplicar
          : ResultadoActualizacion.noDisponible;
    } catch (e) {
      debugPrint('[Actualizador] checkForUpdate: $e');
      return ResultadoActualizacion.noDisponible;
    }
  }

  /// Pantalla completa de Play que bloquea hasta terminar. Para el caso
  /// obligatorio: la app no sirve hasta que se actualice, así que no tiene
  /// sentido dejar al usuario navegando por detrás.
  static Future<ResultadoActualizacion> actualizarBloqueando() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!_puedeInmediato(info)) return ResultadoActualizacion.noDisponible;

      final resultado = await InAppUpdate.performImmediateUpdate();
      return resultado == AppUpdateResult.success
          ? ResultadoActualizacion.aplicada
          : ResultadoActualizacion.canceladaPorUsuario;
    } catch (e) {
      debugPrint('[Actualizador] performImmediateUpdate: $e');
      return ResultadoActualizacion.noDisponible;
    }
  }

  // ─── Interno ─────────────────────────────────────────────────────────────

  /// Play permite el modo inmediato y hay algo que instalar. Incluye el
  /// update inmediato que quedó a medias (el usuario salió de la app mientras
  /// Play instalaba): Google pide retomarlo en vez de dejarlo colgado.
  static bool _puedeInmediato(AppUpdateInfo info) =>
      info.immediateUpdateAllowed &&
      (info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress);
}
