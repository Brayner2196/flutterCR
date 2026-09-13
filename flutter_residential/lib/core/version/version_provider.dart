import 'dart:async';

import 'package:flutter/foundation.dart';

import 'actualizador.dart';
import 'estado_version.dart';
import 'resultado_actualizacion.dart';
import 'version_service.dart';

/// Estado de la actualización dentro de la app.
enum FaseActualizacion {
  /// Nada en curso.
  reposo,

  /// Descargando en segundo plano (Android) o comprobando el hosting (web).
  descargando,

  /// Lista: falta que el usuario confirme el reinicio o la recarga.
  listaParaAplicar,

  /// No se puede actualizar desde aquí; la UI ofrece el enlace a la tienda.
  noDisponible,

  /// Falló la descarga o la instalación.
  fallo,
}

/// Coordina el chequeo de versión y la actualización.
///
/// **No extiende `BaseProvider` a propósito.** `BaseProvider.ejecutar` guarda el
/// error y lo publica para que la pantalla lo pinte, y este chequeo tiene que
/// ser silencioso: si falla, el usuario no debe enterarse de nada, solo entrar
/// a la app. Publicar un error aquí llenaría de mensajes rojos la pantalla de
/// arranque por algo que es opcional.
class VersionProvider extends ChangeNotifier {
  InfoVersion _info = InfoVersion.desconocido;
  FaseActualizacion _fase = FaseActualizacion.reposo;
  bool _consultado = false;
  bool _bannerDescartado = false;

  InfoVersion get info => _info;
  FaseActualizacion get fase => _fase;

  /// Falso hasta que termina la primera consulta. El gate lo usa para no
  /// parpadear mostrando "al día" antes de saberlo.
  bool get consultado => _consultado;

  /// Bloquea la app entera. Solo cuando el backend lo dice explícitamente:
  /// `desconocido` nunca bloquea.
  bool get debeBloquear => _info.bloquea;

  /// Banner visible: hay versión sugerida y el usuario no lo ha cerrado.
  bool get mostrarBanner =>
      _info.estado == EstadoVersion.sugerida && !_bannerDescartado;

  /// Consulta el estado. Se llama una vez al abrir la app.
  ///
  /// [forzar] la repite; se usa al volver del segundo plano, cuando el usuario
  /// pudo haber actualizado desde la tienda por su cuenta.
  Future<void> verificar({bool forzar = false}) async {
    if (_consultado && !forzar) return;

    _info = await VersionService.consultar();
    _consultado = true;

    // Una actualización obligatoria no se puede ignorar: si el banner se había
    // descartado antes con una sugerida, se reinicia.
    if (_info.bloquea) _bannerDescartado = false;

    notifyListeners();

    // La descarga arranca sola en cuanto se sabe que hace falta. El usuario no
    // tiene que pedirla: para cuando lea el banner, ya está lista.
    if (_info.requiereAccion) {
      unawaited(_descargar());
    }
  }

  /// Fuerza el estado bloqueante sin volver a consultar.
  ///
  /// Lo llama el gate cuando el backend responde 426 en cualquier petición: en
  /// ese momento ya se sabe que la app quedó obsoleta y volver a preguntarle a
  /// `/auth/version` sería una ida al servidor para confirmar lo que el
  /// servidor acaba de decir.
  void marcarObsoleta(String mensaje) {
    if (_info.bloquea) return;
    _info = InfoVersion(
      estado: EstadoVersion.obligatoria,
      versionNombre: _info.versionNombre,
      mensaje: mensaje,
      urlTienda: _info.urlTienda,
    );
    _consultado = true;
    _bannerDescartado = false;
    notifyListeners();
    unawaited(_descargar());
  }

  /// Cierra el banner. Solo aplica a la sugerida; vuelve a aparecer en el
  /// siguiente arranque.
  void descartarBanner() {
    if (_info.bloquea) return;
    _bannerDescartado = true;
    notifyListeners();
  }

  /// Aplica lo descargado: reinicia (Android) o recarga (web).
  Future<void> aplicar() async {
    final resultado = _info.bloquea
        ? await Actualizador.actualizarBloqueando()
        : await Actualizador.completar();

    // `aplicada` no necesita notificar: la app se está reiniciando o
    // recargando y este objeto deja de existir en un instante.
    if (resultado == ResultadoActualizacion.fallo) {
      _fase = FaseActualizacion.fallo;
      notifyListeners();
    }
  }

  // ─── Interno ─────────────────────────────────────────────────────────────

  Future<void> _descargar() async {
    _fase = FaseActualizacion.descargando;
    notifyListeners();

    final resultado = await Actualizador.descargarEnSegundoPlano();

    _fase = switch (resultado) {
      ResultadoActualizacion.listaParaAplicar => FaseActualizacion.listaParaAplicar,
      ResultadoActualizacion.noDisponible => FaseActualizacion.noDisponible,
      ResultadoActualizacion.fallo => FaseActualizacion.fallo,
      // `sinNovedad` y `canceladaPorUsuario` vuelven a reposo: no hay nada
      // pendiente, y la UI sigue ofreciendo el enlace a la tienda si hace falta.
      _ => FaseActualizacion.reposo,
    };
    notifyListeners();
  }
}
