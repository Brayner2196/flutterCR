import '../../../core/providers/base_provider.dart';
import '../../vigilancia/models/visita_model.dart';
import '../services/visita_residente_service.dart';

/// Estado de las visitas del residente.
class VisitaProvider extends BaseProvider {
  List<VisitaModel> _visitas = [];
  List<VisitaModel> get visitas => _visitas;

  Future<void> cargar() async {
    final res = await ejecutar(() => VisitaResidenteService.mias());
    if (res != null) _visitas = res;
  }

  Future<VisitaModel?> crear({
    required int propiedadId,
    required String nombreVisitante,
    String? documento,
    String? placa,
    String? motivo,
    int cantidadPersonas = 1,
    String? acompanantes,
    String? franjaDesde,
    String? franjaHasta,
    int? validezHoras,
  }) async {
    final res = await ejecutar(() => VisitaResidenteService.crear(
          propiedadId: propiedadId,
          nombreVisitante: nombreVisitante,
          documento: documento,
          placa: placa,
          motivo: motivo,
          cantidadPersonas: cantidadPersonas,
          acompanantes: acompanantes,
          franjaDesde: franjaDesde,
          franjaHasta: franjaHasta,
          validezHoras: validezHoras,
        ));
    if (res != null) {
      _visitas = [res, ..._visitas];
      notifyListeners();
    }
    return res;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> cancelar(int id) async {
    final res = await ejecutar(() => VisitaResidenteService.cancelar(id));
    if (res == null) return false;
    _visitas = _visitas.map((v) => v.id == id ? res : v).toList();
    notifyListeners();
    return true;
  }

  void limpiarDatos() {
    _visitas = [];
    notifyListeners();
  }
}
