import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import '../models/login_response.dart';
import '../models/multi_tenant_response.dart';
import '../services/auth_service.dart';

enum AuthStatus { inicial, cargando, autenticado, noAutenticado, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.inicial;
  String? _token;
  String? _email;
  String? _rol;
  String? _tenantId;
  String? _nombreConjunto;
  String? _nombre;
  String? _error;

  // Para el flujo multi-tenant: guardamos temporalmente mientras el usuario elige conjunto
  MultiTenantResponse? _multiTenantPendiente;
  String? _passwordTemporal;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get email => _email;
  String? get rol => _rol;
  String? get tenantId => _tenantId;
  String? get nombreConjunto => _nombreConjunto;
  String? get nombre => _nombre;
  String? get error => _error;
  MultiTenantResponse? get multiTenantPendiente => _multiTenantPendiente;

  bool get isLoggedIn => _status == AuthStatus.autenticado;
  bool get isAdmin => _rol == 'TENANT_ADMIN';
  bool get isSuperAdmin => _rol == 'SUPER_ADMIN';
  bool get isResidente => _rol == 'RESIDENTE';

  /// Al iniciar la app: intenta restaurar sesión guardada
  Future<void> cargarSesionGuardada() async {
    _status = AuthStatus.cargando;
    notifyListeners();

    final sesion = await TokenStorage.leerSesion();
    if (sesion['token'] != null) {
      _token = sesion['token'];
      _email = sesion['email'];
      _rol = sesion['rol'];
      _tenantId = sesion['tenantId'];
      _nombreConjunto = sesion['nombreConjunto'];
      _nombre = sesion['nombre'];
      _status = AuthStatus.autenticado;
    } else {
      _status = AuthStatus.noAutenticado;
    }

    notifyListeners();
  }

  /// Paso 1 del login — puede resultar en autenticado o en selección de tenant
  Future<bool> login(String email, String password) async {
    _error = null;

    try {
      final resultado = await AuthService.login(email, password);

      if (resultado is LoginResponse) {
        await _aplicarSesion(resultado);
        return true; // ir a HomeScreen
      }

      if (resultado is MultiTenantResponse) {
        _multiTenantPendiente = resultado;
        _email = email;
        _passwordTemporal = password;
        _status = AuthStatus.noAutenticado;
        notifyListeners();
        return false; // ir a TenantSelectionScreen
      }

      throw Exception('Respuesta inesperada del servidor');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.noAutenticado;
      notifyListeners();
      rethrow;
    }
  }

  /// Paso 2 del login multi-tenant — el usuario eligió su conjunto
  Future<void> seleccionarTenant(String tenantId) async {
    _error = null;

    try {
      final resultado = await AuthService.seleccionarTenant(
        email: _email!,
        password: _passwordTemporal!,
        tenantId: tenantId,
      );
      _multiTenantPendiente = null;
      _passwordTemporal = null;
      await _aplicarSesion(resultado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.noAutenticado;
      notifyListeners();
      rethrow;
    }
  }

  /// Registro de residente pendiente
  Future<String> registro({
    required String nombre,
    required String email,
    required String password,
    required String codigoConjunto,
    String? apto,
    String? torre,
    String? telefono,
  }) async {
    try {
      return await AuthService.registro(
        nombre: nombre,
        email: email,
        password: password,
        codigoConjunto: codigoConjunto,
        apto: apto,
        torre: torre,
        telefono: telefono,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenStorage.borrarSesion();
    _token = null;
    _email = null;
    _rol = null;
    _tenantId = null;
    _nombreConjunto = null;
    _nombre = null;
    _multiTenantPendiente = null;
    _passwordTemporal = null;
    _error = null;
    _status = AuthStatus.noAutenticado;
    notifyListeners();
  }

  Future<void> _aplicarSesion(LoginResponse response) async {
    await TokenStorage.guardarSesion(
      token: response.token,
      email: response.email,
      rol: response.rol,
      tenantId: response.tenantId,
      nombreConjunto: response.nombreConjunto,
      nombre: response.nombre,
    );
    _token = response.token;
    _email = response.email;
    _rol = response.rol;
    _tenantId = response.tenantId;
    _nombreConjunto = response.nombreConjunto;
    _nombre = response.nombre;
    _status = AuthStatus.autenticado;
    notifyListeners();
  }
}
