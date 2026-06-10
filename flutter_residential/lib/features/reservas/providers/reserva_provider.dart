import '../../../core/providers/base_provider.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';

class ReservaProvider extends BaseProvider {
  List<ReservaModel> _reservas = [];
  List<ZonaComunModel> _zonas = [];
  String? _filtroEstado;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<ReservaModel> get reservas => _reservas;
  List<ZonaComunModel> get zonas => _zonas;
  String? get filtroEstado => _filtroEstado;
  int get cantidadPendientes =>
      _reservas.where((r) => r.esPendiente).length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin({String? estado}) async {
    _filtroEstado = estado;
    _reservas = await ejecutar(
      () => ReservaService.listarAdmin(estado: estado),
    ) ?? [];
  }

  Future<void> cargarMisReservas() async {
    _reservas = await ejecutar(() => ReservaService.misReservas()) ?? [];
  }

  Future<void> cargarZonasActivas() async {
    _zonas = await ejecutar(() => ReservaService.zonasActivas()) ?? [];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<ReservaModel> aprobar(int id, {String? motivo}) async {
    final actualizada = await ejecutar(
      () => ReservaService.aprobar(id, motivo: motivo),
    );
    if (actualizada == null) throw Exception(error ?? 'Error al aprobar reserva');
    reemplazar(_reservas, actualizada, (r) => r.id);
    return actualizada;
  }

  Future<ReservaModel> rechazar(int id, String motivo) async {
    final actualizada = await ejecutar(
      () => ReservaService.rechazar(id, motivo),
    );
    if (actualizada == null) throw Exception(error ?? 'Error al rechazar reserva');
    reemplazar(_reservas, actualizada, (r) => r.id);
    return actualizada;
  }

  Future<ReservaModel> crearReserva(Map<String, dynamic> data) async {
    final nueva = await ejecutar(() => ReservaService.crear(data));
    if (nueva == null) throw Exception(error ?? 'Error al crear reserva');
    agregarAlInicio(_reservas, nueva);
    return nueva;
  }

  Future<ReservaModel> cancelarReserva(int id) async {
    final actualizada = await ejecutar(
      () => ReservaService.cancelar(id),
    );
    if (actualizada == null) throw Exception(error ?? 'Error al cancelar reserva');
    reemplazar(_reservas, actualizada, (r) => r.id);
    return actualizada;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Utilities
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Filtra reservas localmente por estado (para la vista del residente).
  List<ReservaModel> filtrarPorEstado(String? estado) {
    if (estado == null) return _reservas;
    return _reservas.where((r) => r.estado == estado).toList();
  }
}
