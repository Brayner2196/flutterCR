import '../../../core/providers/base_provider.dart';
import '../models/vehiculo_model.dart';
import '../services/vehiculo_service.dart';

class VehiculoProvider extends BaseProvider {
  List<VehiculoModel> _vehiculos = [];
  bool _soloPendientes = false;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<VehiculoModel> get vehiculos => _vehiculos;
  bool get soloPendientes => _soloPendientes;
  int get cantidadPendientes =>
      _vehiculos.where((v) => v.esPendiente).length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Admin
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin({bool soloPendientes = false}) async {
    _soloPendientes = soloPendientes;
    _vehiculos =
        await ejecutar(() => VehiculoService.listarAdmin(soloPendientes: soloPendientes)) ?? [];
  }

  Future<void> aprobar(int id) async {
    final actualizado = await ejecutar(() => VehiculoService.aprobar(id));
    if (actualizado == null) throw Exception(error ?? 'Error al aprobar vehículo');
    reemplazar(_vehiculos, actualizado, (v) => v.id);
    // Si estaba filtrando solo pendientes, removerlo de la lista local
    if (_soloPendientes) {
      eliminar(_vehiculos, (v) => v.id == id);
    }
  }

  Future<void> rechazar(int id, {String? motivo}) async {
    final actualizado =
        await ejecutar(() => VehiculoService.rechazar(id, motivo: motivo));
    if (actualizado == null) throw Exception(error ?? 'Error al rechazar vehículo');
    reemplazar(_vehiculos, actualizado, (v) => v.id);
    if (_soloPendientes) {
      eliminar(_vehiculos, (v) => v.id == id);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Residente
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarMisVehiculos(int propiedadId) async {
    _vehiculos =
        await ejecutar(() => VehiculoService.misVehiculos(propiedadId)) ?? [];
  }

  Future<VehiculoModel> registrar(
      Map<String, dynamic> data, int propiedadId) async {
    final nuevo =
        await ejecutar(() => VehiculoService.registrar(data, propiedadId));
    if (nuevo == null) throw Exception(error ?? 'Error al registrar vehículo');
    agregarAlFinal(_vehiculos, nuevo);
    return nuevo;
  }

  Future<void> eliminarVehiculo(int vehiculoId, int propiedadId) async {
    await ejecutar(() => VehiculoService.eliminar(vehiculoId, propiedadId));
    if (error != null) throw Exception(error);
    eliminar(_vehiculos, (v) => v.id == vehiculoId);
  }
}
