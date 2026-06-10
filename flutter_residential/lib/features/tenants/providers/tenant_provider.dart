import '../../../core/providers/base_provider.dart';
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

  Future<void> crear(Map<String, dynamic> datos) async {
    final nuevo = await ejecutar(() => TenantService.crear(datos));
    if (nuevo != null) {
      agregarAlFinal(_tenants, nuevo);
    }
  }

  Future<void> actualizar(int id, Map<String, dynamic> datos) async {
    final actualizado = await ejecutar(
      () => TenantService.actualizar(id, datos),
    );
    if (actualizado != null) {
      reemplazar(_tenants, actualizado, (t) => t.id);
    }
  }

  Future<void> desactivar(int id) async {
    await ejecutar(() => TenantService.desactivar(id));
    _actualizarEstado(id, activo: false);
  }

  Future<void> activar(int id) async {
    await ejecutar(() => TenantService.activar(id));
    _actualizarEstado(id, activo: true);
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
