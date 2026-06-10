import '../../../core/providers/base_provider.dart';
import '../models/abono_model.dart';
import '../models/saldo_favor_model.dart';
import '../services/abono_service.dart';

class AbonoProvider extends BaseProvider {
  List<AbonoModel> _abonos = [];
  SaldoFavorModel? _saldoFavor;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<AbonoModel> get abonos => _abonos;
  SaldoFavorModel? get saldoFavor => _saldoFavor;

  List<AbonoModel> get pendientes =>
      _abonos.where((a) => a.esPendiente).toList();
  List<AbonoModel> get verificados =>
      _abonos.where((a) => a.esVerificado).toList();
  List<AbonoModel> get rechazados =>
      _abonos.where((a) => a.esRechazado).toList();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarMisAbonos() async {
    _abonos = await ejecutar(() => AbonoService.getMisAbonos()) ?? [];
  }

  Future<void> cargarSaldoFavor(int propiedadId) async {
    try {
      _saldoFavor = await AbonoService.getSaldoFavor(propiedadId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarTodosAbonosAdmin() async {
    final results = await ejecutar(
      () => Future.wait([
        AbonoService.listarAbonosAdmin(estado: 'PENDIENTE_VERIFICACION'),
        AbonoService.listarAbonosAdmin(estado: 'VERIFICADO'),
        AbonoService.listarAbonosAdmin(estado: 'RECHAZADO'),
      ]),
    );
    if (results != null) {
      _abonos = [...results[0], ...results[1], ...results[2]];
      notifyListeners();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<AbonoModel> registrar(Map<String, dynamic> data) async {
    final nuevo = await ejecutar(
      () => AbonoService.registrarAbono(data),
    );
    if (nuevo == null) throw Exception(error ?? 'Error al registrar abono');
    agregarAlFinal(_abonos, nuevo);
    return nuevo;
  }

  Future<void> verificar(int id, {String? notas}) async {
    final actualizado = await ejecutar(
      () => AbonoService.verificarAbono(id, notas: notas),
    );
    if (actualizado != null) _actualizarOAgregar(actualizado);
  }

  Future<void> rechazar(int id, String motivo) async {
    final actualizado = await ejecutar(
      () => AbonoService.rechazarAbono(id, motivo),
    );
    if (actualizado != null) _actualizarOAgregar(actualizado);
  }

  /// Helper privado: reemplaza item existente o agrega si no existe
  void _actualizarOAgregar(AbonoModel actualizado) {
    final idx = _abonos.indexWhere((a) => a.id == actualizado.id);
    if (idx != -1) {
      _abonos[idx] = actualizado;
    } else {
      _abonos.add(actualizado);
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Limpiar estado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void limpiarDatos() {
    _abonos.clear();
    _saldoFavor = null;
    limpiarError();
    notifyListeners();
  }
}
