import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/login_response.dart';
import '../models/multi_tenant_response.dart';

class AuthService {
  /// Retorna LoginResponse o MultiTenantResponse según el backend
  static Future<dynamic> login(String email, String password) async {
    final response = await ApiClient.post(
      ApiConstants.login,
      {'email': email, 'password': password},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (body['requiereSeleccion'] == true) {
        return MultiTenantResponse.fromJson(body);
      }
      return LoginResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al iniciar sesión');
  }

  /// Segunda llamada cuando el usuario elige su conjunto (multi-tenant)
  static Future<LoginResponse> seleccionarTenant({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.seleccionarTenant,
      {'email': email, 'password': password, 'tenantId': tenantId},
      requiresAuth: true,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al seleccionar conjunto');
  }

  /// Auto-registro de residente pendiente
  static Future<String> registro({
    required String nombre,
    required String email,
    required String password,
    required String codigoConjunto,
    String? apto,
    String? torre,
    String? telefono,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.registro,
      {
        'nombre': nombre,
        'email': email,
        'password': password,
        'codigoConjunto': codigoConjunto,
        if (apto != null) 'apto': apto,
        if (torre != null) 'torre': torre,
        if (telefono != null) 'telefono': telefono,
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return body['mensaje'] ?? 'Registro exitoso';
    }

    throw Exception(body['message'] ?? 'Error al registrarse');
  }
}
