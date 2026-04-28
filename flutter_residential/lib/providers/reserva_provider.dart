import 'package:flutter/material.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';

class ReservaProvider extends ChangeNotifier {
  List<ReservaModel> _reservas = [];
  List<ZonaComunModel> _zonas = [];
  String? _filtroEstado;
  bool _loading = false;
  String? _error;

  List<ReservaModel> get reservas => _reservas;
  List<ZonaComunModel> get zonas => _zonas;
  String? get filtroEstado => _filtroEstado;
  bool get loading => _loading;
  String? get error => _error;
  int get cantidadPendientes =>
      _reservas.where((r) => r.esPendiente).length;

  // ─── Admin ─────────────────────────────────────

  Future<void> cargarAdmin({String? estado}) async {
    _filtroEstado = estado;
    _setLoading(true);
    try {
      _reservas = await ReservaService.listarAdmin(estado: estado);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<ReservaModel> aprobar(int id, {String? motivo}) async {
    final actualizada = await ReservaService.aprobar(id, motivo: motivo);
    final idx = _reservas.indexWhere((r) => r.id == id);
    if (idx != -1) _reservas[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  Future<ReservaModel> rechazar(int id, String motivo) async {
    final actualizada = await ReservaService.rechazar(id, motivo);
    final idx = _reservas.indexWhere((r) => r.id == id);
    if (idx != -1) _reservas[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  // ─── Residente ────────────────────────────────

  Future<void> cargarMisReservas() async {
    _setLoading(true);
    try {
      _reservas = await ReservaService.misReservas();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarZonasActivas() async {
    try {
      _zonas = await ReservaService.zonasActivas();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<ReservaModel> crearReserva(Map<String, dynamic> data) async {
    final nueva = await ReservaService.crear(data);
    _reservas.insert(0, nueva);
    notifyListeners();
    return nueva;
  }

  Future<ReservaModel> cancelarReserva(int id) async {
    final actualizada = await ReservaService.cancelar(id);
    final idx = _reservas.indexWhere((r) => r.id == id);
    if (idx != -1) _reservas[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  /// Filtra reservas localmente por estado (para la vista del residente).
  List<ReservaModel> filtrarPorEstado(String? estado) {
    if (estado == null) return _reservas;
    return _reservas.where((r) => r.estado == estado).toList();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
