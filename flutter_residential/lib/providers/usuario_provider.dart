import 'package:flutter/material.dart';
import '../models/usuario_response.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends ChangeNotifier {
  List<UsuarioResponse> _todos = [];
  bool _loading = false;
  String? _error;

  /// Todos los usuarios sin importar su estado.
  List<UsuarioResponse> get usuarios => _todos;

  /// Filtrado cliente: estado == 'ACTIVO'
  List<UsuarioResponse> get activos =>
      _todos.where((u) => u.estado == 'ACTIVO').toList();

  /// Filtrado cliente: estado == 'PENDIENTE'
  List<UsuarioResponse> get pendientes =>
      _todos.where((u) => u.estado == 'PENDIENTE').toList();

  /// Filtrado cliente: estado == 'INACTIVO'
  List<UsuarioResponse> get inactivos =>
      _todos.where((u) => u.estado == 'INACTIVO').toList();

  List<UsuarioResponse> get rechazados =>
      _todos.where((u) => u.estado == 'RECHAZADO').toList();

  bool get loading => _loading;
  String? get error => _error;

  /// Única llamada a la API: trae todos los usuarios.
  Future<void> cargarTodos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _todos = await UsuarioService.listarTodos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> crear(Map<String, dynamic> data) async {
    final nuevo = await UsuarioService.crear(data);
    _todos.add(nuevo);
    notifyListeners();
  }

  Future<void> aprobar(int id) async {
    try {
      final actualizado = await UsuarioService.aprobar(id);
      _reemplazar(actualizado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rechazar(int id) async {
    try {
      final actualizado = await UsuarioService.rechazar(id);
      _reemplazar(actualizado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> actualizar(int id, Map<String, dynamic> data) async {
    final actualizado = await UsuarioService.actualizar(id, data);
    _reemplazar(actualizado);
  }

  void _reemplazar(UsuarioResponse actualizado) {
    final index = _todos.indexWhere((u) => u.id == actualizado.id);
    if (index != -1) _todos[index] = actualizado;
    notifyListeners();
  }

  void limpiar() {
    _todos = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
