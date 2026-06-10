import '../../../core/providers/base_provider.dart';
import '../models/pago_model.dart';
import '../services/pago_service.dart';

class PagosProvider extends BaseProvider {
  List<PagoModel> _pagos = [];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PagoModel> get pagos => _pagos;

  List<PagoModel> get pendientes => _pagos.where((p) => p.esPendiente).toList();
  List<PagoModel> get verificados =>
      _pagos.where((p) => p.esVerificado).toList();
  List<PagoModel> get rechazados => _pagos.where((p) => p.esRechazado).toList();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarMisPagos({int? propiedadId}) async {
    _pagos = await ejecutar(() => PagoService.getMisPagos(propiedadId: propiedadId)) ?? [];
  }

  Future<void> cargarPagosAdmin({
    String estado = 'PENDIENTE_VERIFICACION',
  }) async {
    _pagos = await ejecutar(() => PagoService.listarPagosAdmin(estado: estado)) ?? [];
  }

  /// Carga los tres estados a la vez para que los tabs muestren datos
  Future<void> cargarTodosPagosAdmin() async {
    final results = await ejecutar(
      () => Future.wait([
        PagoService.listarPagosAdmin(estado: 'PENDIENTE_VERIFICACION'),
        PagoService.listarPagosAdmin(estado: 'VERIFICADO'),
        PagoService.listarPagosAdmin(estado: 'RECHAZADO'),
      ]),
    );
    if (results != null) {
      _pagos = [...results[0], ...results[1], ...results[2]];
      notifyListeners();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> verificar(int id, {String? notas}) async {
    final actualizado = await ejecutar(
      () => PagoService.verificarPago(id, notas: notas),
    );
    if (actualizado != null) _actualizarOAgregar(actualizado);
  }

  Future<void> rechazar(int id, String motivo) async {
    final actualizado = await ejecutar(
      () => PagoService.rechazarPago(id, motivo),
    );
    if (actualizado != null) _actualizarOAgregar(actualizado);
  }

  /// Helper privado: reemplaza item existente o agrega si no existe
  void _actualizarOAgregar(PagoModel actualizado) {
    final idx = _pagos.indexWhere((p) => p.id == actualizado.id);
    if (idx != -1) {
      _pagos[idx] = actualizado;
    } else {
      _pagos.add(actualizado);
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Limpiar estado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void limpiarDatos() {
    _pagos.clear();
    limpiarError();
    notifyListeners();
  }
}
