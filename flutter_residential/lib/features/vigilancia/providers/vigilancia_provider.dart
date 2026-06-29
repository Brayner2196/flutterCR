import '../../../core/providers/base_provider.dart';
import '../models/bitacora_acceso_model.dart';
import '../models/paquete_model.dart';
import '../services/vigilancia_service.dart';

/// Estado del área de vigilancia: bitácora reciente y paquetes pendientes.
/// El selector de propiedades busca on-demand (paginado), no se cachea aquí.
class VigilanciaProvider extends BaseProvider {
  List<BitacoraAccesoModel> _bitacora = [];
  List<PaqueteModel> _paquetesPendientes = [];

  List<BitacoraAccesoModel> get bitacora => _bitacora;
  List<PaqueteModel> get paquetesPendientes => _paquetesPendientes;
  int get totalPendientes => _paquetesPendientes.length;

  Future<void> cargarBitacora({int limite = 50}) async {
    final res = await ejecutar(() => VigilanciaService.bitacora(limite: limite));
    if (res != null) _bitacora = res;
  }

  Future<void> cargarPaquetesPendientes() async {
    final res = await ejecutar(() => VigilanciaService.paquetesPendientes());
    if (res != null) _paquetesPendientes = res;
  }

  /// Refresca los datos que alimentan el dashboard del vigilante.
  Future<void> cargarResumen() async {
    await Future.wait([cargarPaquetesPendientes(), cargarBitacora(limite: 20)]);
  }

  /// Registra un paquete y refresca la lista de pendientes.
  Future<PaqueteModel?> registrarPaquete({
    required int propiedadId,
    required String descripcion,
    String? remitente,
    String? transportadora,
  }) async {
    final res = await ejecutar(() => VigilanciaService.registrarPaquete(
          propiedadId: propiedadId,
          descripcion: descripcion,
          remitente: remitente,
          transportadora: transportadora,
        ));
    if (res != null) {
      _paquetesPendientes = [res, ..._paquetesPendientes];
      notifyListeners();
    }
    return res;
  }

  /// Marca un paquete como entregado y lo saca de pendientes.
  Future<PaqueteModel?> entregarPaquete(int id, {String? entregadoA}) async {
    final res = await ejecutar(
        () => VigilanciaService.entregarPaquete(id, entregadoA: entregadoA));
    if (res != null) {
      _paquetesPendientes =
          _paquetesPendientes.where((p) => p.id != id).toList();
      notifyListeners();
    }
    return res;
  }

  void limpiarDatos() {
    _bitacora = [];
    _paquetesPendientes = [];
    notifyListeners();
  }
}
