import '../../../core/providers/base_provider.dart';
import '../models/configuracion_plan_pago_model.dart';
import '../models/cuota_plan_model.dart';
import '../models/plan_pago_model.dart';
import '../services/plan_pago_service.dart';

/// Provider compartido para admin y residente en el módulo de Plan de Pago.
class PlanPagoProvider extends BaseProvider {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Estado privado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PlanPagoModel> _planes = [];
  PlanPagoModel? _planDetalle;
  PlanPagoModel? _planActivo;
  ConfiguracionPlanPagoModel _config =
      ConfiguracionPlanPagoModel.defaultConfig;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PlanPagoModel> get planes => _planes;
  PlanPagoModel? get planDetalle => _planDetalle;
  PlanPagoModel? get planActivo => _planActivo;
  ConfiguracionPlanPagoModel get config => _config;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarConfigAdmin() async {
    _config = await ejecutar(() => PlanPagoService.obtenerConfigAdmin()) ?? _config;
  }

  Future<void> cargarConfigResidente() async {
    try {
      _config = await ejecutar(() => PlanPagoService.obtenerConfigResidente()) ?? _config;
    } catch (_) {}
  }

  Future<void> cargarPlanesAdmin({String? estado}) async {
    _planes = await ejecutar(
      () => PlanPagoService.listarAdmin(estado: estado),
    ) ?? [];
  }

  Future<void> cargarMisPlanes() async {
    _planes = await ejecutar(() => PlanPagoService.misPlanes()) ?? [];
  }

  Future<void> cargarDetalle(int id) async {
    _planDetalle = await ejecutar(() => PlanPagoService.detalle(id));
  }

  /// miPlanActivo() retorna Future<PlanPagoModel?> — llamada directa sin ejecutar()
  /// para evitar inferencia de T nullable. Fallo silencioso: sin plan activo es normal.
  Future<void> cargarPlanActivo() async {
    setLoading(true);
    try {
      _planActivo = await PlanPagoService.miPlanActivo();
    } catch (_) {
      _planActivo = null;
    } finally {
      setLoading(false);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> guardarConfig(ConfiguracionPlanPagoModel config) async {
    _config = await ejecutar(() => PlanPagoService.guardarConfig(config)) ?? _config;
  }

  Future<PlanPagoModel> decidir(
      int id, bool aprobar, {String? motivo, String? nota}) async {
    final result = await ejecutar(() => PlanPagoService.decidir(
      id,
      aprobar,
      motivoRechazo: motivo,
      nota: nota,
    ));
    if (result == null) throw Exception(error ?? 'Error al decidir plan');
    reemplazar(_planes, result, (p) => p.id);
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  Future<CuotaPlanModel> marcarCuotaPagada(int planId, int cuotaId,
      {String? nota}) async {
    final cuota = await ejecutar(() => PlanPagoService.marcarCuotaPagada(
      planId,
      cuotaId,
      nota: nota,
    ));
    if (cuota == null) throw Exception(error ?? 'Error al marcar cuota pagada');
    await cargarDetalle(planId);
    return cuota;
  }

  Future<PlanPagoModel> cancelar(int id, {String? nota}) async {
    final result = await ejecutar(
      () => PlanPagoService.cancelarPlan(id, nota: nota),
    );
    if (result == null) throw Exception(error ?? 'Error al cancelar plan');
    reemplazar(_planes, result, (p) => p.id);
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  Future<PlanPagoModel> solicitar({
    required List<int> cobrosIds,
    required int numeroCuotas,
    String? observaciones,
  }) async {
    final plan = await ejecutar(() => PlanPagoService.solicitar(
      cobrosIds: cobrosIds,
      numeroCuotas: numeroCuotas,
      observaciones: observaciones,
    ));
    if (plan == null) throw Exception(error ?? 'Error al solicitar plan');
    agregarAlInicio(_planes, plan);
    if (plan.esActivo) _planActivo = plan;
    return plan;
  }
}
