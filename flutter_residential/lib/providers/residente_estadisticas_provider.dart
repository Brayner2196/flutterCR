import 'package:flutter/material.dart';
import '../models/cobro_model.dart';
import '../models/pago_model.dart';
import '../models/residente_estadisticas_model.dart';
import '../services/cobro_service.dart';
import '../services/pago_service.dart';

/// Provider que carga y calcula estadísticas del residente
/// combinando datos de cobros y pagos existentes.
class ResidenteEstadisticasProvider extends ChangeNotifier {
  ResidenteEstadisticasModel? _estadisticas;
  bool _loading = false;
  String? _error;

  ResidenteEstadisticasModel? get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargar() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Cargar cobros y pagos en paralelo
      final results = await Future.wait([
        CobroService.getMisCobros(),
        PagoService.getMisPagos(),
      ]);

      final cobros = results[0] as List<CobroModel>;
      final pagos = results[1] as List<PagoModel>;

      _estadisticas = ResidenteEstadisticasModel.fromData(
        todosLosCobros: cobros,
        todosLosPagos: pagos,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => cargar();

  void limpiar() {
    _estadisticas = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
