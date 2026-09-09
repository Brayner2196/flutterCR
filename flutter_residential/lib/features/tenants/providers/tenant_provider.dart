import '../../../core/providers/base_provider.dart';
import '../models/operacion_destructiva_response.dart';
import '../models/tenant_response.dart';
import '../services/tenant_service.dart';

class TenantProvider extends BaseProvider {
  List<TenantResponse> _tenants = [];

  List<TenantResponse> get tenants => _tenants;

  Future<void> cargarTodos() async {
    final resultado = await ejecutar(() => TenantService.listarTodos());
    if (resultado != null) {
      _tenants = resultado;
    }
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> crear(Map<String, dynamic> datos) async {
    final nuevo = await ejecutar(() => TenantService.crear(datos));
    if (nuevo == null) return false;
    agregarAlFinal(_tenants, nuevo);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> actualizar(int id, Map<String, dynamic> datos) async {
    final actualizado = await ejecutar(
      () => TenantService.actualizar(id, datos),
    );
    if (actualizado == null) return false;
    reemplazar(_tenants, actualizado, (t) => t.id);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> desactivar(int id) async {
    await ejecutar(() => TenantService.desactivar(id));
    // Sin el corte, el conjunto se pintaba como desactivado en la lista aunque
    // el backend hubiera rechazado la operación.
    if (error != null) return false;
    _actualizarEstado(id, activo: false);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> activar(int id) async {
    await ejecutar(() => TenantService.activar(id));
    if (error != null) return false;
    _actualizarEstado(id, activo: true);
    return true;
  }

  // ─── Operaciones destructivas ────────────────────────────────────────────

  /// Vacía los datos del conjunto. El conjunto SIGUE existiendo, así que no se
  /// quita de la lista: solo se recarga para refrescar el conteo de usuarios.
  Future<OperacionDestructivaResponse?> vaciarDatos({
    required int id,
    required String codigoConfirmacion,
  }) async {
    final resultado = await ejecutar(() => TenantService.vaciarDatos(
          id: id,
          codigoConfirmacion: codigoConfirmacion,
        ));
    if (resultado != null) {
      await cargarTodos();
    }
    return resultado;
  }

  /// Elimina el conjunto por completo y lo saca de la lista en memoria, para
  /// no dejar en pantalla una tarjeta que ya no existe en el servidor.
  Future<OperacionDestructivaResponse?> eliminarDefinitivo({
    required int id,
    required String codigoConfirmacion,
  }) async {
    final resultado = await ejecutar(() => TenantService.eliminarDefinitivo(
          id: id,
          codigoConfirmacion: codigoConfirmacion,
        ));
    if (resultado != null) {
      eliminar(_tenants, (t) => t.id == id);
    }
    return resultado;
  }

  void limpiarDatos() {
    _tenants.clear();
    limpiarError();
    setLoading(false);
  }

  void _actualizarEstado(int id, {required bool activo}) {
    final index = _tenants.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = _tenants[index];
      _tenants[index] = TenantResponse(
        id: t.id,
        schemaName: t.schemaName,
        nombre: t.nombre,
        codigo: t.codigo,
        activo: activo,
        direccion: t.direccion,
      );
      notifyListeners();
    }
  }
}
