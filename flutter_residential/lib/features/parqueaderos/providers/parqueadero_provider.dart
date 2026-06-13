import '../../../core/providers/base_provider.dart';
import '../models/configuracion_parqueadero_model.dart';
import '../models/parqueadero_model.dart';
import '../services/parqueadero_service.dart';

class ParqueaderoProvider extends BaseProvider {
  List<ParqueaderoModel> _parqueaderos = [];
  ConfiguracionParqueaderoModel _config = ConfiguracionParqueaderoModel.vacia();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<ParqueaderoModel> get parqueaderos => _parqueaderos;
  ConfiguracionParqueaderoModel get config => _config;

  int get totalAsignados =>
      _parqueaderos.where((p) => p.tieneAsignacion).length;
  int get totalLibres =>
      _parqueaderos.where((p) => !p.tieneAsignacion).length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Admin: Configuración
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarConfig() async {
    final res = await ejecutar(() => ParqueaderoService.obtenerConfig());
    if (res != null) _config = res;
  }

  Future<ConfiguracionParqueaderoModel> guardarConfig(
      Map<String, dynamic> data) async {
    final res = await ejecutar(() => ParqueaderoService.guardarConfig(data));
    if (res == null) throw Exception(error ?? 'Error al guardar configuración');
    _config = res;
    return res;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Admin: Parqueaderos
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin() async {
    _parqueaderos = await ejecutar(() => ParqueaderoService.listarAdmin()) ?? [];
  }

  /// Retorna el resultado bulk con {creados, duplicados, items}.
  Future<Map<String, dynamic>> crearBulk(List<String> identificadores) async {
    final res = await ejecutar(
      () => ParqueaderoService.crearBulk(identificadores),
    );
    if (res == null) throw Exception(error ?? 'Error al crear parqueaderos');
    // Recarga la lista para reflejar los nuevos registros
    await cargarAdmin();
    return res;
  }

  Future<void> asignarPropiedad(int parqueaderoId, int? propiedadId) async {
    final actualizado = await ejecutar(
      () => ParqueaderoService.asignarPropiedad(parqueaderoId, propiedadId),
    );
    if (actualizado == null) throw Exception(error ?? 'Error al asignar propiedad');
    reemplazar(_parqueaderos, actualizado, (p) => p.id);
  }

  Future<void> eliminarParqueadero(int id) async {
    await ejecutar(() => ParqueaderoService.eliminar(id));
    if (error != null) throw Exception(error);
    eliminar(_parqueaderos, (p) => p.id == id);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Residente: Mis parqueaderos
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarMisParqueaderos(int propiedadId) async {
    _parqueaderos =
        await ejecutar(() => ParqueaderoService.misParqueaderos(propiedadId)) ?? [];
  }

  Future<void> cambiarVehiculo(
      int parqueaderoId, int? vehiculoId, int propiedadId) async {
    final actualizado = await ejecutar(
      () => ParqueaderoService.cambiarVehiculo(parqueaderoId, vehiculoId, propiedadId),
    );
    if (actualizado == null) throw Exception(error ?? 'Error al cambiar vehículo');
    reemplazar(_parqueaderos, actualizado, (p) => p.id);
  }
}
