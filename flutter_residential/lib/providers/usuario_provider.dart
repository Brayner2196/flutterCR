import 'package:flutter/material.dart';
import '../models/usuario_response.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends ChangeNotifier {
  List<UsuarioResponse> _usuarios = [];
  List<UsuarioResponse> _pendientes = [];
  bool _loading = false;
  String? _error;

  List<UsuarioResponse> get usuarios => _usuarios;
  List<UsuarioResponse> get pendientes => _pendientes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargarTodos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await UsuarioService.listarTodos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPendientes() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pendientes = await UsuarioService.listarPendientes();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> aprobar(int id) async {
    try {
      await UsuarioService.aprobar(id);
      _pendientes.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rechazar(int id) async {
    try {
      await UsuarioService.rechazar(id);
      _pendientes.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void limpiar() {
    _usuarios = [];
    _pendientes = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
