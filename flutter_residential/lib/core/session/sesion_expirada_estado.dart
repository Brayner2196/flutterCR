/// Estado global del cierre por sesión expirada.
///
/// Vive en core (no en el widget del modal) para que AppToast (core) y
/// MensajeOperacion (shared) puedan consultarlo sin que core dependa de shared.
class SesionExpiradaEstado {
  SesionExpiradaEstado._();

  static bool _enCurso = false;

  /// true desde que aparece el modal hasta que el usuario queda en el login.
  static bool get enCurso => _enCurso;

  /// Marca el inicio. Devuelve false si ya había uno en curso: varias
  /// peticiones pueden fallar a la vez y solo debe abrirse un modal.
  static bool iniciar() {
    if (_enCurso) return false;
    _enCurso = true;
    return true;
  }

  static void terminar() => _enCurso = false;
}
