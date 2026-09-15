import '../../../core/providers/base_provider.dart';
import '../models/configuracion_plan_pago_model.dart';
import '../models/elegibilidad_acuerdo_model.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';
import '../services/plan_pago_service.dart';

/// Provider compartido por admin y residente en el módulo de acuerdos de pago.
class PlanPagoProvider extends BaseProvider {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Estado privado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PlanPagoModel> _planes = [];
  PlanPagoModel? _planDetalle;
  PlanPagoModel? _planActivo;
  ConfiguracionPlanPagoModel _config = ConfiguracionPlanPagoModel.defaultConfig;
  ElegibilidadAcuerdoModel _elegibilidad = ElegibilidadAcuerdoModel.desconocida;
  SimulacionAcuerdoModel? _simulacion;
  bool _simulando = false;
  String? _errorSimulacion;

  /// Contador de simulaciones en vuelo. El residente cambia de 3 a 6 cuotas más
  /// rápido de lo que responde la red, y sin esto la respuesta de la petición
  /// vieja puede llegar después y pintar el desglose que ya no corresponde.
  int _simulacionSeq = 0;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PlanPagoModel> get planes => _planes;
  PlanPagoModel? get planDetalle => _planDetalle;
  PlanPagoModel? get planActivo => _planActivo;
  ConfiguracionPlanPagoModel get config => _config;
  ElegibilidadAcuerdoModel get elegibilidad => _elegibilidad;
  SimulacionAcuerdoModel? get simulacion => _simulacion;
  bool get simulando => _simulando;
  String? get errorSimulacion => _errorSimulacion;

  /// Acuerdo vigente (pendiente o activo) dentro de los ya cargados.
  PlanPagoModel? get acuerdoVigente {
    for (final p in _planes) {
      if (p.estaVigente) return p;
    }
    return _planActivo != null && _planActivo!.estaVigente ? _planActivo : null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Carga
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarConfigAdmin() async {
    _config = await ejecutar(() => PlanPagoService.obtenerConfigAdmin()) ?? _config;
  }

  Future<void> cargarConfigResidente() async {
    try {
      _config =
          await ejecutar(() => PlanPagoService.obtenerConfigResidente()) ?? _config;
    } catch (_) {}
  }

  Future<void> cargarPlanesAdmin({String? estado}) async {
    _planes = await ejecutar(() => PlanPagoService.listarAdmin(estado: estado)) ?? [];
  }

  Future<void> cargarMisPlanes() async {
    _planes = await ejecutar(() => PlanPagoService.misPlanes()) ?? [];
  }

  Future<void> cargarDetalle(int id) async {
    _planDetalle = await ejecutar(() => PlanPagoService.detalle(id));
  }

  /// Sin acuerdo vigente es un caso normal: se resuelve a null sin marcar error.
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

  /// Consulta si la propiedad puede pedir un acuerdo. Falla en silencio: el
  /// estado de cuenta debe seguir funcionando aunque el módulo esté caído.
  Future<ElegibilidadAcuerdoModel> cargarElegibilidad({int? propiedadId}) async {
    try {
      final res = await PlanPagoService.elegibilidad(propiedadId: propiedadId);
      _elegibilidad = res;
    } catch (_) {
      _elegibilidad = ElegibilidadAcuerdoModel.desconocida;
    }
    notifyListeners();
    return _elegibilidad;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Simulación
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Pide la previsualización al backend. La app no calcula montos: si algo
  /// falla se muestra el error y NO un número aproximado, porque un número
  /// aproximado en una pantalla de acuerdo es una promesa que no se cumple.
  Future<void> simular({int? propiedadId, required int numeroCuotas}) async {
    final seq = ++_simulacionSeq;
    _simulando = true;
    _errorSimulacion = null;
    notifyListeners();

    try {
      final res = await PlanPagoService.simular(
          propiedadId: propiedadId, numeroCuotas: numeroCuotas);
      if (seq != _simulacionSeq) return; // llegó tarde: hay otra en curso
      _simulacion = res;
    } catch (e) {
      if (seq != _simulacionSeq) return;
      _simulacion = null;
      _errorSimulacion = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (seq == _simulacionSeq) {
        _simulando = false;
        notifyListeners();
      }
    }
  }

  void limpiarSimulacion() {
    _simulacion = null;
    _errorSimulacion = null;
    _simulacionSeq++;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// true si el backend aceptó. En false el motivo queda en [error]: `ejecutar`
  /// lo atrapa y NO relanza, así que un try/catch alrededor nunca se dispara.
  Future<bool> guardarConfig(ConfiguracionPlanPagoModel config) async {
    final guardada = await ejecutar(() => PlanPagoService.guardarConfig(config));
    if (guardada == null) return false; // se conserva la config anterior
    _config = guardada;
    notifyListeners();
    return true;
  }

  Future<PlanPagoModel> decidir(int id, bool aprobar,
      {String? motivo, String? nota}) async {
    final result = await ejecutar(() => PlanPagoService.decidir(
          id,
          aprobar,
          motivoRechazo: motivo,
          nota: nota,
        ));
    if (result == null) throw Exception(error ?? 'Error al decidir el acuerdo');
    reemplazar(_planes, result, (p) => p.id);
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  Future<PlanPagoModel> cancelar(int id, {String? nota}) async {
    final result =
        await ejecutar(() => PlanPagoService.cancelarPlan(id, nota: nota));
    if (result == null) throw Exception(error ?? 'Error al cancelar el acuerdo');
    reemplazar(_planes, result, (p) => p.id);
    _planDetalle = result;
    notifyListeners();
    return result;
  }

  Future<PlanPagoModel> solicitar({
    int? propiedadId,
    required int numeroCuotas,
    String? observaciones,
  }) async {
    final plan = await ejecutar(() => PlanPagoService.solicitar(
          propiedadId: propiedadId,
          numeroCuotas: numeroCuotas,
          observaciones: observaciones,
        ));
    if (plan == null) throw Exception(error ?? 'Error al solicitar el acuerdo');
    agregarAlInicio(_planes, plan);
    if (plan.estaVigente) _planActivo = plan;
    notifyListeners();
    return plan;
  }
}
