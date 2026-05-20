import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../../usuarios/models/usuario_propiedad_response.dart';

class PropiedadService {
  /// Tipos de propiedad del conjunto (público, para el registro)
  static Future<List<TipoPropiedadNodo>> getTiposArbol(String codigo) async {
    final res = await ApiClient.get(
      '${ApiConstants.authTiposPropiedad}?codigo=$codigo',
      requiresAuth: false,
    );
    return BaseApiService.parseList(
        res, TipoPropiedadNodo.fromJson, 'Error al obtener tipos de propiedad');
  }

  /// Tipos de propiedad del tenant (admin autenticado)
  static Future<List<TipoPropiedadNodo>> getTiposArbolAdmin() async {
    final res = await ApiClient.get(ApiConstants.tiposPropiedad);
    return BaseApiService.parseList(
        res, TipoPropiedadNodo.fromJson, 'Error al obtener tipos de propiedad');
  }

  /// Mis propiedades del residente autenticado
  static Future<List<UsuarioPropiedadResponse>> getMisPropiedades() async {
    final res = await ApiClient.get(ApiConstants.misPropiedades);
    return BaseApiService.parseList(
        res, UsuarioPropiedadResponse.fromJson, 'Error al obtener propiedades');
  }

  /// Propiedades de un residente específico (admin)
  static Future<List<UsuarioPropiedadResponse>> getPropiedadesDeUsuario(int usuarioId) async {
    final res = await ApiClient.get(ApiConstants.propiedadesDeUsuario(usuarioId));
    return BaseApiService.parseList(
        res, UsuarioPropiedadResponse.fromJson, 'Error al obtener propiedades del usuario');
  }

  /// Actualizar estado de una propiedad (admin)
  static Future<void> actualizarEstadoPropiedad(int propiedadId, String estado) async {
    final res = await ApiClient.patch(
        '${ApiConstants.propiedadEstado(propiedadId)}?estado=$estado');
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al actualizar estado');
  }

  /// Marcar propiedad como principal del residente (admin)
  static Future<void> marcarComoPrincipal(int propiedadId, int usuarioId) async {
    final res = await ApiClient.patch(
        ApiConstants.marcarPropiedadPrincipal(propiedadId, usuarioId));
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al marcar como principal');
  }

  /// Crear propiedad por path (admin) — retorna el ID de la propiedad hoja
  static Future<int> crearPropiedad(List<Map<String, dynamic>> path) async {
    final res = await ApiClient.post(
      ApiConstants.propiedades,
      {'propiedadPath': path},
      requiresAuth: true,
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['id'] as int;
    }
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al crear propiedad');
    throw Exception('Error al crear propiedad'); // unreachable
  }

  /// Crear tipo de propiedad (admin)
  static Future<void> crearTipo({
    required String nombre,
    String? descripcion,
    int? parentId,
    bool esFacturable = false,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.tiposPropiedad,
      {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (parentId != null) 'parentId': parentId,
        'esFacturable': esFacturable,
      },
      requiresAuth: true,
    );
    BaseApiService.assertSuccess(res,
        successCodes: [200, 201], fallbackMsg: 'Error al crear tipo');
  }

  /// Actualizar tipo de propiedad (admin)
  static Future<void> actualizarTipo(int id,
      {required String nombre, String? descripcion, bool esFacturable = false}) async {
    final res = await ApiClient.put(
      '${ApiConstants.tiposPropiedad}/$id',
      {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'esFacturable': esFacturable,
      },
    );
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al actualizar tipo');
  }

  /// Desactivar tipo de propiedad (admin)
  static Future<void> desactivarTipo(int id) async {
    final res = await ApiClient.delete('${ApiConstants.tiposPropiedad}/$id');
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al desactivar tipo');
  }

  /// Listar todas las propiedades (admin)
  static Future<List<Map<String, dynamic>>> listarPropiedades() async {
    final res = await ApiClient.get(ApiConstants.propiedades);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al listar propiedades');
    return [];
  }

  /// Asignar residente a propiedad (admin)
  static Future<void> asignarUsuario(int propiedadId, int usuarioId) async {
    final res = await ApiClient.post(
      '${ApiConstants.propiedades}/$propiedadId/usuarios/$usuarioId',
      {},
      requiresAuth: true,
    );
    BaseApiService.assertSuccess(res,
        successCodes: [204, 200], fallbackMsg: 'Error al asignar usuario');
  }

  /// Quitar residente de propiedad (admin)
  static Future<void> quitarUsuario(int propiedadId, int usuarioId) async {
    final res = await ApiClient.delete(
        '${ApiConstants.propiedades}/$propiedadId/usuarios/$usuarioId');
    BaseApiService.assertSuccess(res,
        successCodes: [204], fallbackMsg: 'Error al quitar usuario');
  }
}
