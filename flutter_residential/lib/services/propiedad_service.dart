import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../models/usuario_propiedad_response.dart';

class PropiedadService {
  /// Tipos de propiedad del conjunto (público, para el registro)
  static Future<List<TipoPropiedadNodo>> getTiposArbol(String codigo) async {
    final response = await ApiClient.get(
      '${ApiConstants.authTiposPropiedad}?codigo=$codigo',
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((e) => TipoPropiedadNodo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener tipos de propiedad');
  }

  /// Tipos de propiedad del tenant (admin autenticado)
  static Future<List<TipoPropiedadNodo>> getTiposArbolAdmin() async {
    final response = await ApiClient.get(ApiConstants.tiposPropiedad);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((e) => TipoPropiedadNodo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener tipos de propiedad');
  }

  /// Mis propiedades del residente autenticado
  static Future<List<UsuarioPropiedadResponse>> getMisPropiedades() async {
    final response = await ApiClient.get(ApiConstants.misPropiedades);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((e) =>
              UsuarioPropiedadResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener propiedades');
  }

  /// Crear tipo de propiedad (admin)
  static Future<void> crearTipo({
    required String nombre,
    String? descripcion,
    int? parentId,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.tiposPropiedad,
      {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (parentId != null) 'parentId': parentId,
      },
      requiresAuth: true,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al crear tipo');
    }
  }

  /// Actualizar tipo de propiedad (admin)
  static Future<void> actualizarTipo(int id,
      {required String nombre, String? descripcion}) async {
    final response = await ApiClient.put(
      '${ApiConstants.tiposPropiedad}/$id',
      {'nombre': nombre, if (descripcion != null) 'descripcion': descripcion},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al actualizar tipo');
    }
  }

  /// Desactivar tipo de propiedad (admin)
  static Future<void> desactivarTipo(int id) async {
    final response =
        await ApiClient.delete('${ApiConstants.tiposPropiedad}/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al desactivar tipo');
    }
  }

  /// Listar todas las propiedades (admin)
  static Future<List<Map<String, dynamic>>> listarPropiedades() async {
    final response = await ApiClient.get(ApiConstants.propiedades);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List).cast<Map<String, dynamic>>();
    }
    throw Exception(body['message'] ?? 'Error al listar propiedades');
  }

  /// Asignar residente a propiedad (admin)
  static Future<void> asignarUsuario(int propiedadId, int usuarioId) async {
    final response = await ApiClient.post(
      '${ApiConstants.propiedades}/$propiedadId/usuarios/$usuarioId',
      {},
      requiresAuth: true,
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al asignar usuario');
    }
  }

  /// Quitar residente de propiedad (admin)
  static Future<void> quitarUsuario(int propiedadId, int usuarioId) async {
    final response = await ApiClient.delete(
      '${ApiConstants.propiedades}/$propiedadId/usuarios/$usuarioId',
    );
    if (response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al quitar usuario');
    }
  }
}
