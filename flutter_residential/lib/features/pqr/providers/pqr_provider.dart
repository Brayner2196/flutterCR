import '../../../core/providers/base_provider.dart';
import '../models/pqr_model.dart';
import '../services/pqr_service.dart';

class PqrProvider extends BaseProvider {
  List<PqrModel> _pqrs = [];
  String? _filtroEstado;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<PqrModel> get pqrs => _pqrs;
  String? get filtroEstado => _filtroEstado;
  int get cantidadPendientes =>
      _pqrs.where((p) => p.esPendiente).length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin({String? estado}) async {
    _filtroEstado = estado;
    _pqrs = await ejecutar(
      () => PqrService.listarAdmin(estado: estado),
    ) ?? [];
  }

  Future<void> cargarMisPqrs() async {
    _pqrs = await ejecutar(() => PqrService.misPqrs()) ?? [];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<PqrModel> responder(int id, String respuesta) async {
    final actualizada = await ejecutar(
      () => PqrService.responder(id, respuesta),
    );
    if (actualizada == null) throw Exception(error ?? 'Error al responder PQR');
    reemplazar(_pqrs, actualizada, (p) => p.id);
    return actualizada;
  }

  Future<PqrModel> cambiarEstado(int id, String estado,
      {String? comentario}) async {
    final actualizada = await ejecutar(
      () => PqrService.cambiarEstado(id, estado, comentario: comentario),
    );
    if (actualizada == null) throw Exception(error ?? 'Error al cambiar estado');
    reemplazar(_pqrs, actualizada, (p) => p.id);
    return actualizada;
  }

  Future<PqrModel> crearPqr({
    required String tipo,
    required String asunto,
    required String descripcion,
    int? propiedadId,
  }) async {
    final nueva = await ejecutar(() => PqrService.crear(
      tipo: tipo,
      asunto: asunto,
      descripcion: descripcion,
      propiedadId: propiedadId,
    ));
    if (nueva == null) throw Exception(error ?? 'Error al crear PQR');
    agregarAlInicio(_pqrs, nueva);
    return nueva;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Utilities
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Filtra PQRs localmente por estado (para la vista del residente).
  List<PqrModel> filtrarPorEstado(String? estado) {
    if (estado == null) return _pqrs;
    return _pqrs.where((p) => p.estado == estado).toList();
  }

  /// Sincroniza la lista interna con las PQRs cargadas por ConsejoProvider.
  /// Permite que las acciones de responder/cambiarEstado actualicen la lista
  /// correcta sin necesidad de un reload completo.
  void sincronizarDesdeConsejo(List<PqrModel> pqrs) {
    _pqrs = List.of(pqrs);
    notifyListeners();
  }
}
