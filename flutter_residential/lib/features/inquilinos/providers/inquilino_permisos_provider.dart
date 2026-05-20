import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

/// Provider que carga y expone los permisos del inquilino autenticado.
/// Solo aplica cuando el usuario tiene rol INQUILINO.
class InquilinoPermisosProvider extends ChangeNotifier {
  Set<String> _permisos = {};
  bool _cargado = false;
  bool _cargando = false;

  Set<String> get permisos => _permisos;
  bool get cargado => _cargado;
  bool get cargando => _cargando;

  bool tienePermiso(String permiso) => _permisos.contains(permiso);

  /// Carga los permisos desde el backend. Llama esto al iniciar sesión como INQUILINO.
  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.misPermisos);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _permisos = Set<String>.from(body['permisos'] ?? []);
      }
      _cargado = true;
    } catch (_) {
      // Si falla, dejamos los permisos vacíos (acceso restringido por defecto)
      _permisos = {};
      _cargado = true;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Limpia los permisos al cerrar sesión.
  void limpiar() {
    _permisos = {};
    _cargado = false;
    _cargando = false;
    notifyListeners();
  }
}
