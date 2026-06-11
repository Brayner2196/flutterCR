import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/base_provider.dart';
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

  static const _cachePrefix = 'stats_residente_v1_';

  // ─── Cache stale-while-revalidate ─────────────────────

  /// Intenta cargar datos del cache local. Retorna true si había cache.
  Future<bool> _cargarDesdeCache(int propiedadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$propiedadId');
      if (raw == null) return false;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _estadisticas =
          ResidenteEstadisticasModel.fromJson(data['stats'] as Map<String, dynamic>);
      _saldoFavor = (data['saldoFavor'] as num).toDouble();
      notifyListeners();
      return true;
    } catch (_) {
      return false; // cache corrupto — ignorar y cargar del API
    }
  }

  Future<void> _guardarCache(
      int propiedadId, ResidenteEstadisticasModel stats, double saldo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_cachePrefix$propiedadId',
        jsonEncode({'stats': stats.toJson(), 'saldoFavor': saldo}),
      );
    } catch (_) {} // fallo de cache no es crítico
  }

  Future<void> _limpiarCache(int propiedadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$propiedadId');
    } catch (_) {}
  }

  // ─── Helpers ──────────────────────────────────────────

  Future<double> _obtenerSaldoFavor(int? pid) async {
    if (pid == null) return 0.0;
    try {
      final sf = await AbonoService.getSaldoFavor(pid);
      return sf.saldo;
    } catch (_) {
      return 0.0;
    }
  }

  // ─── Carga principal ───────────────────────────────────

  /// Carga cobros, pagos y saldo a favor en paralelo.
  /// Si hay cache, lo muestra de inmediato y refresca en background sin spinner.
  Future<void> cargar({int? propiedadId}) async {
    final pid = propiedadId ?? _propiedadIdActual;
    if (propiedadId != null) _propiedadIdActual = propiedadId;

    // 1. Mostrar cache de inmediato si existe (el usuario ve datos al instante)
    final teniaCacheCache = pid != null && await _cargarDesdeCache(pid);

    // 2. Mostrar spinner solo si no había cache
    if (!teniaCacheCache) setLoading(true);

    try {
      // 3. Las 3 llamadas en paralelo — tiempo total = max(cobros, pagos, saldo)
      final cobrosF = CobroService.getMisCobros(propiedadId: pid);
      final pagosF = PagoService.getMisPagos(propiedadId: pid);
      final saldoF = _obtenerSaldoFavor(pid);

      final cobros = await cobrosF;
      final pagos = await pagosF;
      final saldo = await saldoF;

      _estadisticas = ResidenteEstadisticasModel.fromData(
        todosLosCobros: cobros,
        todosLosPagos: pagos,
      );
      _saldoFavor = saldo;

      limpiarError();

      // 4. Persistir en cache para la próxima entrada
      if (pid != null) await _guardarCache(pid, _estadisticas!, _saldoFavor);
    } catch (e) {
      // Si había cache, no mostrar error — el usuario ya ve datos útiles
      if (!teniaCacheCache) {
        setError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> refrescar() => cargar();

  void limpiarDatos() {
    if (_propiedadIdActual != null) _limpiarCache(_propiedadIdActual!);
    _estadisticas = null;
    _saldoFavor = 0.0;
    _propiedadIdActual = null;
    limpiarError();
    setLoading(false);
  }
}
