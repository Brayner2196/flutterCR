import 'package:flutter/material.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';

class ReservaProvider extends ChangeNotifier {
  List<ReservaModel> _reservas = [];
  String? _filtroEstado;
  bool _loading = false;
  String? _error;

  List<ReservaModel> get reservas => _reservas;
  String? get filtroEstado => _filtroEstado;
  bool get loading => _loading;
  String? get error => _error;
  int get cantidadPendientes =>
      _reservas.where((r) => r.esPendiente).length;

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

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
