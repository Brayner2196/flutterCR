import 'package:flutter/material.dart';
import '../models/votacion_model.dart';
import '../services/votacion_service.dart';

class VotacionProvider extends ChangeNotifier {
  List<VotacionModel> _votaciones = [];
  VotacionModel? _seleccionada;
  bool _loading = false;
  String? _error;

  List<VotacionModel> get votaciones => _votaciones;
  VotacionModel? get seleccionada => _seleccionada;
  bool get loading => _loading;
  String? get error => _error;
  int get pendientesDeVotar =>
      _votaciones.where((v) => !v.yaVote && v.estado == 'ABIERTA').length;

  // ─── Admin ───────────────────────────────────────────────────────────────

  Future<void> cargarAdmin({String? estado}) async {
    _setLoading(true);
    try {
      _votaciones = await VotacionService.listarAdmin(estado: estado);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<VotacionModel> crear(Map<String, dynamic> body) async {
    final nueva = await VotacionService.crear(body);
    _votaciones.insert(0, nueva);
    notifyListeners();
    return nueva;
  }

  Future<VotacionModel> actualizar(int id, Map<String, dynamic> body) async {
    final actualizada = await VotacionService.actualizar(id, body);
    _reemplazar(actualizada);
    return actualizada;
  }

  Future<VotacionModel> cambiarEstado(int id, String estado) async {
    final actualizada = await VotacionService.cambiarEstado(id, estado);
    _reemplazar(actualizada);
    return actualizada;
  }

  Future<VotacionModel> cargarResultados(int id) async {
    final resultado = await VotacionService.resultados(id);
    _seleccionada = resultado;
    _reemplazar(resultado);
    return resultado;
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  Future<void> cargarResidente() async {
    _setLoading(true);
    try {
      _votaciones = await VotacionService.listarResidente();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<VotacionModel> cargarDetalle(int id) async {
    final detalle = await VotacionService.detalleResidente(id);
    _seleccionada = detalle;
    notifyListeners();
    return detalle;
  }

  Future<VotacionModel> votar(int id, Map<String, dynamic> body) async {
    final resultado = await VotacionService.votar(id, body);
    _seleccionada = resultado;
    _reemplazar(resultado);
    return resultado;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _reemplazar(VotacionModel v) {
    final idx = _votaciones.indexWhere((x) => x.id == v.id);
    if (idx != -1) _votaciones[idx] = v;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
