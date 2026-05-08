import 'package:flutter/material.dart';
import '../models/anuncio_model.dart';
import '../services/anuncio_service.dart';

class AnuncioProvider extends ChangeNotifier {
  List<AnuncioModel> _anuncios = [];
  List<AnuncioVistaModel> _vistas = [];
  bool _loading = false;
  String? _error;

  List<AnuncioModel> get anuncios => _anuncios;
  List<AnuncioVistaModel> get vistas => _vistas;
  bool get loading => _loading;
  String? get error => _error;
  int get noVistos => _anuncios.where((a) => !a.vistoPorMi).length;

  // ─── Admin ───────────────────────────────────────────────────────────────

  Future<void> cargarAdmin({String? estado}) async {
    _setLoading(true);
    try {
      _anuncios = await AnuncioService.listarAdmin(estado: estado);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<AnuncioModel> crear(Map<String, dynamic> body) async {
    final nuevo = await AnuncioService.crear(body);
    _anuncios.insert(0, nuevo);
    notifyListeners();
    return nuevo;
  }

  Future<AnuncioModel> actualizar(int id, Map<String, dynamic> body) async {
    final actualizado = await AnuncioService.actualizar(id, body);
    _reemplazar(actualizado);
    return actualizado;
  }

  Future<AnuncioModel> cambiarEstado(int id, String estado) async {
    final actualizado = await AnuncioService.cambiarEstado(id, estado);
    _reemplazar(actualizado);
    return actualizado;
  }

  Future<void> eliminar(int id) async {
    await AnuncioService.eliminar(id);
    _anuncios.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<List<AnuncioVistaModel>> cargarVistas(int id) async {
    _vistas = await AnuncioService.listarVistas(id);
    notifyListeners();
    return _vistas;
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  Future<void> cargarResidente() async {
    _setLoading(true);
    try {
      _anuncios = await AnuncioService.listarResidente();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> marcarVisto(int id) async {
    try {
      final actualizado = await AnuncioService.marcarVisto(id);
      _reemplazar(actualizado);
    } catch (_) {
      // idempotente: si falla no es crítico
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _reemplazar(AnuncioModel a) {
    final idx = _anuncios.indexWhere((x) => x.id == a.id);
    if (idx != -1) _anuncios[idx] = a;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
