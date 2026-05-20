import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../features/usuarios/models/usuario_response.dart';

class InquilinoService {
  /// Lista los inquilinos de la unidad del propietario autenticado.
  static Future<List<UsuarioResponse>> listarInquilinos() async {
    final res = await ApiClient.get(ApiConstants.misInquilinos);
    _verificarRespuesta(res, 'Error al cargar los inquilinos');
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => UsuarioResponse.fromJson(e)).toList();
  }

  /// Crea un nuevo inquilino en la unidad del propietario.
  static Future<UsuarioResponse> crearInquilino({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.misInquilinos,
      {
        'nombre': nombre,
        'email': email,
        'password': password,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      },
      requiresAuth: true,
    );
    _verificarRespuesta(res, 'Error al crear el inquilino');
    return UsuarioResponse.fromJson(jsonDecode(res.body));
  }

  /// Elimina un inquilino de la unidad del propietario.
  static Future<void> eliminarInquilino(int id) async {
    final res = await ApiClient.delete(ApiConstants.eliminarInquilino(id));
    if (res.statusCode != 204) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Error al eliminar el inquilino');
    }
  }

  /// Retorna la lista de permisos activos del inquilino.
  static Future<List<String>> listarPermisos(int id) async {
    final res = await ApiClient.get(ApiConstants.permisosInquilino(id));
    _verificarRespuesta(res, 'Error al cargar los permisos');
    final Map<String, dynamic> body = jsonDecode(res.body);
    return List<String>.from(body['permisos'] ?? []);
  }

  /// Reemplaza todos los permisos del inquilino con la lista indicada.
  static Future<List<String>> actualizarPermisos(int id, List<String> permisos) async {
    final res = await ApiClient.put(
      ApiConstants.permisosInquilino(id),
      {'permisos': permisos},
    );
    _verificarRespuesta(res, 'Error al actualizar los permisos');
    final Map<String, dynamic> body = jsonDecode(res.body);
    return List<String>.from(body['permisos'] ?? []);
  }

  static void _verificarRespuesta(http.Response res, String mensajeError) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      String mensaje = mensajeError;
      try {
        final body = jsonDecode(res.body);
        mensaje = body['message'] ?? mensajeError;
      } catch (_) {}
      throw Exception(mensaje);
    }
  }
}
