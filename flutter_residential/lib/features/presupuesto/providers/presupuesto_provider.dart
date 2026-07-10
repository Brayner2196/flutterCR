import '../../../core/providers/base_provider.dart';
import '../models/gasto_registrado_model.dart';
import '../models/presupuesto_model.dart';
import '../services/presupuesto_service.dart';

class PresupuestoProvider extends BaseProvider {
  /// Lista de presupuestos (admin: todos; residente: todos)
  List<PresupuestoModel> _presupuestos = [];

  /// Detalle del presupuesto seleccionado (admin)
  PresupuestoModel? _detalle;

  /// Presupuesto activo (residente)
  PresupuestoModel? _activo;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PresupuestoModel> get presupuestos => _presupuestos;
  PresupuestoModel? get detalle => _detalle;
  PresupuestoModel? get activo => _activo;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarListaAdmin() async {
    _presupuestos = await ejecutar(() => PresupuestoService.listarAdmin()) ?? [];
  }

  Future<void> cargarListaResidente() async {
    _presupuestos = await ejecutar(() => PresupuestoService.listarResidente()) ?? [];
  }

  Future<void> cargarDetalle(int id) async {
    _detalle = await ejecutar(() => PresupuestoService.detalleAdmin(id));
  }

  /// presupuestoActivo() retorna Future'PresupuestoModel' — llamada directa sin ejecutar()
  /// para evitar inferencia de T nullable. Null = sin presupuesto activo, es válido.
  Future<void> cargarActivo() async {
    setLoading(true);
    try {
      _activo = await PresupuestoService.presupuestoActivo();
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<PresupuestoModel> crear(Map<String, dynamic> body) async {
    final p = await ejecutar(() => PresupuestoService.crear(body));
    if (p == null) throw Exception(error ?? 'Error al crear presupuesto');
    agregarAlInicio(_presupuestos, p);
    return p;
  }

  Future<PresupuestoModel> actualizar(int id, Map<String, dynamic> body) async {
    final p = await ejecutar(() => PresupuestoService.actualizar(id, body));
    if (p == null) throw Exception(error ?? 'Error al actualizar presupuesto');
    _reemplazarEnLista(p);
    if (_detalle?.id == id) _detalle = p;
    notifyListeners();
    return p;
  }

  Future<void> toggleActivo(int id, {required bool activo}) async {
    final p = await ejecutar(
      () => PresupuestoService.toggleActivo(id, activo: activo),
    );
    if (p == null) return;
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
    final gasto = await ejecutar(
      () => PresupuestoService.registrarGasto(presupuestoId, body),
    );
    if (gasto == null) throw Exception(error ?? 'Error al registrar gasto');
    await cargarDetalle(presupuestoId);
    return gasto;
  }

  Future<void> eliminarGasto(int presupuestoId, int gastoId) async {
    await ejecutar(
      () => PresupuestoService.eliminarGasto(presupuestoId, gastoId),
    );
    await cargarDetalle(presupuestoId);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Helpers privados
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
