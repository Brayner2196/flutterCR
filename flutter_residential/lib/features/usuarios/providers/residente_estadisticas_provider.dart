import '../../../core/providers/base_provider.dart';
import '../../pagos/models/cobro_model.dart';
import '../../pagos/models/pago_model.dart';
import '../models/residente_estadisticas_model.dart';
import '../../pagos/services/abono_service.dart';
import '../../pagos/services/cobro_service.dart';
import '../../pagos/services/pago_service.dart';

class ResidenteEstadisticasProvider extends BaseProvider {
  ResidenteEstadisticasModel? _estadisticas;
  double _saldoFavor = 0.0;

  /// propiedadId de la última carga — permite refrescar con el mismo filtro.
  int? _propiedadIdActual;

  ResidenteEstadisticasModel? get estadisticas => _estadisticas;
  double get saldoFavor => _saldoFavor;

  /// Carga cobros y pagos filtrados por [propiedadId].
  /// Si se omite, usa el último propiedadId cargado (para refrescar).
  Future<void> cargar({int? propiedadId}) async {
    final pid = propiedadId ?? _propiedadIdActual;
    if (propiedadId != null) _propiedadIdActual = propiedadId;

    setLoading(true);
    try {
      final results = await Future.wait([
        CobroService.getMisCobros(propiedadId: pid),
        PagoService.getMisPagos(propiedadId: pid),
      ]);

      final cobros = results[0] as List<CobroModel>;
      final pagos = results[1] as List<PagoModel>;

      _estadisticas = ResidenteEstadisticasModel.fromData(
        todosLosCobros: cobros,
        todosLosPagos: pagos,
      );

      // Saldo a favor — siempre por propiedadId específica
      final propIdParaSaldo = pid ?? (cobros.isNotEmpty ? cobros.first.propiedadId : null);
      if (propIdParaSaldo != null) {
        try {
          final sf = await AbonoService.getSaldoFavor(propIdParaSaldo);
          _saldoFavor = sf.saldo;
        } catch (_) {
          _saldoFavor = 0.0;
        }
      }

      limpiarError();
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<void> refrescar() => cargar();

  void limpiarDatos() {
    _estadisticas = null;
    _saldoFavor = 0.0;
    _propiedadIdActual = null;
    limpiarError();
    setLoading(false);
  }
}
