import 'package:flutter/material.dart';
import '../models/configuracion_plan_pago_model.dart';
import '../models/cuota_plan_model.dart';
import '../models/plan_pago_model.dart';
import '../services/plan_pago_service.dart';

/// Provider compartido para admin y residente en el módulo de Plan de Pago.
class PlanPagoProvider extends ChangeNotifier {
  // ── Estado ───────────────────────────────────────────────────────

  bool _loading = false;
  String? _error;

  List<PlanPagoModel> _planes = [];
  PlanPagoModel? _planDetalle;
  PlanPagoModel? _planActivo;
  ConfiguracionPlanPagoModel _config =
      ConfiguracionPlanPagoModel.defaultConfig;

  // ── Getters ──────────────────────────────────────────────────────

  bool get loading => _loading;
  String? get error => _error;
  List<PlanPagoModel> get planes => _planes;
  PlanPagoModel? get planDetalle => _planDetalle;
  PlanPagoModel? get planActivo => _planActivo;
  ConfiguracionPlanPagoModel get config => _config;

  // ── Admin ─────────────────────────────────────────────────────────

  Future<void> cargarConfigAdmin() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _config = await PlanPagoService.obtenerConfigAdmin();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> guardarConfig(ConfiguracionPlanPagoModel config) async {
    _loading = true;
    notifyListeners();
    try {
      _config = await PlanPagoService.guardarConfig(config);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPlanesAdmin({String? estado}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _planes = await PlanPagoService.listarAdmin(estado: estado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    _loading = true;
    notifyListeners();
    try {
      _planDetalle = await PlanPagoService.detalle(id);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PlanPagoModel> decidir(
      int id, bool aprobar, {String? motivo, String? nota}) async {
    final result =
        await PlanPagoService.decidir(id, aprobar, motivoRechazo: motivo, nota: nota);
    // Actualizar en la lista local
    _planes = _planes.map((p) => p.id == id ? result : p).toList();
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  Future<CuotaPlanModel> marcarCuotaPagada(int planId, int cuotaId,
      {String? nota}) async {
    final cuota = await PlanPagoService.marcarCuotaPagada(planId, cuotaId, nota: nota);
    // Refrescar detalle
    await cargarDetalle(planId);
    return cuota;
  }

  Future<PlanPagoModel> cancelar(int id, {String? nota}) async {
    final result = await PlanPagoService.cancelarPlan(id, nota: nota);
    _planes = _planes.map((p) => p.id == id ? result : p).toList();
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  // ── Residente ─────────────────────────────────────────────────────

  Future<void> cargarConfigResidente() async {
    try {
      _config = await PlanPagoService.obtenerConfigResidente();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarMisPlanes() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _planes = await PlanPagoService.misPlanes();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPlanActivo() async {
    try {
      _planActivo = await PlanPagoService.miPlanActivo();
      notifyListeners();
    } catch (_) {}
  }

  Future<PlanPagoModel> solicitar({
    required List<int> cobrosIds,
    required int numeroCuotas,
    String? observaciones,
  }) async {
    final plan = await PlanPagoService.solicitar(
      cobrosIds: cobrosIds,
      numeroCuotas: numeroCuotas,
      observaciones: observaciones,
    );
    _planes.insert(0, plan);
    if (plan.esActivo) _planActivo = plan;
    notifyListeners();
    return plan;
  }
}
