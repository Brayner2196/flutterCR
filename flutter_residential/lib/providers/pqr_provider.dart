import 'package:flutter/material.dart';
import '../models/pqr_model.dart';
import '../services/pqr_service.dart';

class PqrProvider extends ChangeNotifier {
  List<PqrModel> _pqrs = [];
  String? _filtroEstado;
  bool _loading = false;
  String? _error;

  List<PqrModel> get pqrs => _pqrs;
  String? get filtroEstado => _filtroEstado;
  bool get loading => _loading;
  String? get error => _error;
  int get cantidadPendientes =>
      _pqrs.where((p) => p.esPendiente).length;

  Future<void> cargarAdmin({String? estado}) async {
    _filtroEstado = estado;
    _setLoading(true);
    try {
      _pqrs = await PqrService.listarAdmin(estado: estado);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<PqrModel> responder(int id, String respuesta) async {
    final actualizada = await PqrService.responder(id, respuesta);
    final idx = _pqrs.indexWhere((p) => p.id == id);
    if (idx != -1) _pqrs[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  Future<PqrModel> cambiarEstado(int id, String estado) async {
    final actualizada = await PqrService.cambiarEstado(id, estado);
    final idx = _pqrs.indexWhere((p) => p.id == id);
    if (idx != -1) _pqrs[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
