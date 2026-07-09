import 'dart:async';

import '../../../core/providers/base_provider.dart';
import '../models/acta_model.dart';
import '../services/acta_service.dart';

/// Estado de las actas de reunión por voz.
/// Incluye un polling ligero mientras exista un acta PROCESANDO para
/// refrescar automáticamente cuando Whisper termina la transcripción.
class ActaProvider extends BaseProvider {
  List<ActaModel> _actas = [];
  Timer? _pollTimer;

  List<ActaModel> get actas => _actas;

  bool get hayProcesando => _actas.any((a) => a.esProcesando);

  // ─── Cargar ───────────────────────────────────────────────────

  Future<void> cargar() async {
    _actas = await ejecutar(() => ActaService.listar()) ?? _actas;
    _gestionarPolling();
  }

  /// Refresco silencioso (sin spinner) usado por el polling.
  Future<void> _refrescarSilencioso() async {
    try {
      _actas = await ActaService.listar();
      notifyListeners();
    } catch (_) {
      // silencioso: el próximo tick lo reintenta
    }
    _gestionarPolling();
  }

  // ─── Acciones (solo presidente — el backend valida el cargo) ──

  Future<ActaModel?> crear({
    required String titulo,
    required String audioPath,
    int? duracionSegundos,
  }) async {
    final acta = await ejecutar(() => ActaService.crear(
          titulo: titulo,
          audioPath: audioPath,
          duracionSegundos: duracionSegundos,
        ));
    if (acta != null) {
      agregarAlInicio(_actas, acta);
      _gestionarPolling();
    }
    return acta;
  }

  Future<ActaModel?> guardarEdicion(int id,
      {String? titulo, String? contenido}) async {
    final acta = await ejecutar(
        () => ActaService.actualizar(id, titulo: titulo, contenido: contenido));
    if (acta != null) reemplazar(_actas, acta, (a) => a.id);
    return acta;
  }

  Future<ActaModel?> finalizar(int id) async {
    final acta = await ejecutar(() => ActaService.finalizar(id));
    if (acta != null) reemplazar(_actas, acta, (a) => a.id);
    return acta;
  }

  Future<ActaModel?> reintentar(int id) async {
    final acta = await ejecutar(() => ActaService.reintentar(id));
    if (acta != null) {
      reemplazar(_actas, acta, (a) => a.id);
      _gestionarPolling();
    }
    return acta;
  }

  Future<bool> eliminarActa(int id) async {
    final ok = await ejecutar(() async {
      await ActaService.eliminar(id);
      return true;
    });
    if (ok == true) {
      eliminar(_actas, (a) => a.id == id);
      return true;
    }
    return false;
  }

  // ─── Polling mientras hay transcripciones en curso ────────────

  void _gestionarPolling() {
    if (hayProcesando) {
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 15),
        (_) => _refrescarSilencioso(),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
