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
    } catch (_) {
      return ResultadoActualizacion.noDisponible;
    }
  }

  /// Instala lo descargado y reinicia la app. Solo tras `listaParaAplicar`.
  static Future<ResultadoActualizacion> completar() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return ResultadoActualizacion.aplicada;
    } catch (_) {
      return ResultadoActualizacion.fallo;
    }
  }

  /// Pantalla completa de Play que bloquea hasta terminar. Para el caso
  /// obligatorio: la app no sirve hasta que se actualice, así que no tiene
  /// sentido dejar al usuario navegando por detrás.
  static Future<ResultadoActualizacion> actualizarBloqueando() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.immediateUpdateAllowed) {
        return ResultadoActualizacion.noDisponible;
      }

      final resultado = await InAppUpdate.performImmediateUpdate();
      return resultado == AppUpdateResult.success
          ? ResultadoActualizacion.aplicada
          : ResultadoActualizacion.canceladaPorUsuario;
    } catch (_) {
      return ResultadoActualizacion.noDisponible;
    }
  }
}
