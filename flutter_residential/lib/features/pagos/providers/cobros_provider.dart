import '../../../core/providers/base_provider.dart';
import '../models/cobro_model.dart';
import '../models/estado_cuenta_model.dart';
import '../models/periodo_cobro_model.dart';
import '../services/cobro_service.dart';

class CobrosProvider extends BaseProvider {
  EstadoCuentaModel? _estadoCuenta;
  List<CobroModel> _cobros = [];
  List<PeriodoCobroModel> _periodos = [];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  EstadoCuentaModel? get estadoCuenta => _estadoCuenta;
  List<CobroModel> get cobros => _cobros;
  List<PeriodoCobroModel> get periodos => _periodos;

  List<CobroModel> get pendientes => _cobros.where((c) => c.esPendiente).toList();
  List<CobroModel> get vencidos => _cobros.where((c) => c.esVencido).toList();
  List<CobroModel> get pagados => _cobros.where((c) => c.esPagado).toList();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarEstadoCuenta({int? propiedadId}) async {
    _estadoCuenta = await ejecutar(() async {
      final cuenta = await CobroService.getEstadoCuenta(propiedadId: propiedadId);
      _cobros = cuenta.cobrosActivos;
      return cuenta;
    });
  }

  Future<void> cargarMisCobros({int? propiedadId}) async {
    _cobros = await ejecutar(() => CobroService.getMisCobros(propiedadId: propiedadId)) ?? [];
  }

  Future<void> cargarHistorial({int? propiedadId}) async {
    _cobros = await ejecutar(() => CobroService.getHistorial(propiedadId: propiedadId)) ?? [];
  }

  Future<void> cargarPeriodos() async {
    _periodos = await ejecutar(() => CobroService.listarPeriodos()) ?? [];
  }

  Future<void> cargarCobrosAdmin({int? periodoId, String? estado}) async {
    _cobros = await ejecutar(
      () => CobroService.listarCobrosAdmin(
        periodoId: periodoId,
        estado: estado,
      ),
    ) ?? [];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<PeriodoCobroModel> abrirPeriodo(Map<String, dynamic> data) async {
    final nuevo = await ejecutar(() => CobroService.abrirPeriodo(data));
    if (nuevo == null) throw Exception(error ?? 'Error al abrir periodo');
    agregarAlInicio(_periodos, nuevo);
    return nuevo;
  }

  Future<void> cerrarPeriodo(int id) async {
    final actualizado = await ejecutar(
      () => CobroService.cerrarPeriodo(id),
    );
    if (actualizado != null) reemplazar(_periodos, actualizado, (p) => p.id);
  }

  Future<List<CobroModel>> generarCobros(int anio, int mes) async {
    final nuevos = await ejecutar(
      () => CobroService.generarCobros(anio, mes),
    );
    if (nuevos == null) throw Exception(error ?? 'Error al generar cobros');
    _cobros = nuevos;
    notifyListeners();
    return nuevos;
  }

  Future<CobroModel> crearCobroEspecial(Map<String, dynamic> data) async {
    final nuevo = await ejecutar(
      () => CobroService.crearCobroEspecial(data),
    );
    if (nuevo == null) throw Exception(error ?? 'Error al crear cobro especial');
    notifyListeners();
    return nuevo;
  }

  Future<CobroModel> exonerar(int id, String nota) async {
    final actualizado = await ejecutar(
      () => CobroService.exonerar(id, nota),
    );
    if (actualizado == null) throw Exception(error ?? 'Error al exonerar cobro');
    reemplazar(_cobros, actualizado, (c) => c.id);
    return actualizado;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Limpiar estado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void limpiarDatos() {
    _estadoCuenta = null;
    _cobros.clear();
    _periodos.clear();
    limpiarError();
    notifyListeners();
  }
}
