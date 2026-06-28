import '../../../core/providers/base_provider.dart';
import '../../vigilancia/models/paquete_model.dart';
import '../services/paquete_residente_service.dart';

/// Estado de la paquetería del residente.
class PaqueteResidenteProvider extends BaseProvider {
  List<PaqueteModel> _paquetes = [];
  List<PaqueteModel> get paquetes => _paquetes;

  int get pendientes => _paquetes.where((p) => p.esRecibido).length;

  Future<void> cargar() async {
    final res = await ejecutar(() => PaqueteResidenteService.mios());
    if (res != null) _paquetes = res;
  }

  void limpiar() {
    _paquetes = [];
    notifyListeners();
  }
}
