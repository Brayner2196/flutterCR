import 'package:flutter/material.dart';
import '../models/tenant_response.dart';
import '../services/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  List<TenantResponse> _tenants = [];
  bool _loading = false;
  String? _error;

  List<TenantResponse> get tenants => _tenants;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargarTodos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tenants = await TenantService.listarTodos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> crear(Map<String, dynamic> datos) async {
    try {
      final nuevo = await TenantService.crear(datos);
      _tenants.add(nuevo);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> actualizar(int id, Map<String, dynamic> datos) async {
    try {
      final actualizado = await TenantService.actualizar(id, datos);
      final index = _tenants.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tenants[index] = actualizado;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> desactivar(int id) async {
    try {
      await TenantService.desactivar(id);
      final index = _tenants.indexWhere((t) => t.id == id);
      if (index != -1) {
        final t = _tenants[index];
        _tenants[index] = TenantResponse(
          id: t.id,
          schemaName: t.schemaName,
          nombre: t.nombre,
          codigo: t.codigo,
          activo: false,
          direccion: t.direccion,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void limpiar() {
    _tenants = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
