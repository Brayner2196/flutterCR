import 'package:flutter/material.dart';
import '../models/gasto_registrado_model.dart';
import '../models/presupuesto_model.dart';
import '../services/presupuesto_service.dart';

class PresupuestoProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  /// Lista de presupuestos (admin: todos; residente: todos)
  List<PresupuestoModel> _presupuestos = [];

  /// Detalle del presupuesto seleccionado (admin)
  PresupuestoModel? _detalle;

  /// Presupuesto activo (residente)
  PresupuestoModel? _activo;

  // ── Getters ───────────────────────────────────────────────────────

  bool get loading => _loading;
  String? get error => _error;
  List<PresupuestoModel> get presupuestos => _presupuestos;
  PresupuestoModel? get detalle => _detalle;
  PresupuestoModel? get activo => _activo;

  // ── Admin ─────────────────────────────────────────────────────────

  Future<void> cargarListaAdmin() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _presupuestos = await PresupuestoService.listarAdmin();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _detalle = await PresupuestoService.detalleAdmin(id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PresupuestoModel> crear(Map<String, dynamic> body) async {
    final p = await PresupuestoService.crear(body);
    _presupuestos = [p, ..._presupuestos];
    notifyListeners();
    return p;
  }

  Future<PresupuestoModel> actualizar(int id, Map<String, dynamic> body) async {
    final p = await PresupuestoService.actualizar(id, body);
    _reemplazarEnLista(p);
    if (_detalle?.id == id) _detalle = p;
    notifyListeners();
    return p;
  }

  Future<void> toggleActivo(int id, {required bool activo}) async {
    final p = await PresupuestoService.toggleActivo(id, activo: activo);
    // Si se activó, desmarcar los demás en lista local
    if (activo) {
      _presupuestos = _presupuestos
          .map((e) => e.id == id ? p : _desactivarLocal(e))
          .toList();
    } else {
      _reemplazarEnLista(p);
    }
    if (_detalle?.id == id) _detalle = p;
    notifyListeners();
  }

  Future<GastoRegistradoModel> registrarGasto(
      int presupuestoId, Map<String, dynamic> body) async {
    final gasto = await PresupuestoService.registrarGasto(presupuestoId, body);
    // Refrescar detalle para recalcular ejecutado
    await cargarDetalle(presupuestoId);
    return gasto;
  }

  Future<void> eliminarGasto(int presupuestoId, int gastoId) async {
    await PresupuestoService.eliminarGasto(presupuestoId, gastoId);
    await cargarDetalle(presupuestoId);
  }

  // ── Residente ─────────────────────────────────────────────────────

  Future<void> cargarActivo() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _activo = await PresupuestoService.presupuestoActivo();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarListaResidente() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _presupuestos = await PresupuestoService.listarResidente();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  void _reemplazarEnLista(PresupuestoModel p) {
    _presupuestos = _presupuestos.map((e) => e.id == p.id ? p : e).toList();
  }

  /// Retorna una copia "local" del presupuesto con activo=false (sin llamada al backend)
  PresupuestoModel _desactivarLocal(PresupuestoModel p) => PresupuestoModel(
        id: p.id,
        anio: p.anio,
        titulo: p.titulo,
        montoTotalPresupuestado: p.montoTotalPresupuestado,
        montoTotalEjecutado: p.montoTotalEjecutado,
        montoTotalPendiente: p.montoTotalPendiente,
        porcentajeEjecucionGeneral: p.porcentajeEjecucionGeneral,
        activo: false,
        creadoEn: p.creadoEn,
        actualizadoEn: p.actualizadoEn,
        categorias: p.categorias,
      );
}
