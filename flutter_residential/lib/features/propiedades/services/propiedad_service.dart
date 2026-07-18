import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../models/valor_tipo_propiedad.dart';
import '../models/propiedad_admin.dart';
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

  // ── Valores permitidos por tipo (catálogo) ────────────────────────────────

  /// Valores permitidos de un nivel (público, para el registro).
  /// [parentValorId] es el id del valor elegido en el nivel anterior (null en la raíz).
  static Future<List<ValorTipoPropiedad>> getValoresPublico(
      String codigo, int tipoId, {int? parentValorId}) async {
    final params = <String, String>{'codigo': codigo};
    if (parentValorId != null) params['parentValorId'] = '$parentValorId';
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await ApiClient.get(
      '${ApiConstants.authValoresPropiedad(tipoId)}?$query',
      requiresAuth: false,
    );
    return BaseApiService.parseList(
        res, ValorTipoPropiedad.fromJson, 'Error al obtener valores permitidos');
  }

  /// Valores permitidos de un nivel (admin autenticado).
  static Future<List<ValorTipoPropiedad>> getValoresAdmin(
      int tipoId, {int? parentValorId}) async {
    final q = parentValorId != null ? '?parentValorId=$parentValorId' : '';
    final res = await ApiClient.get('${ApiConstants.valoresPorTipo(tipoId)}$q');
    return BaseApiService.parseList(
        res, ValorTipoPropiedad.fromJson, 'Error al obtener valores permitidos');
  }

  /// Todos los valores del tipo (activos e inactivos), para la gestión.
  static Future<List<ValorTipoPropiedad>> getValoresTodos(int tipoId) async {
    final res = await ApiClient.get(ApiConstants.valoresTodosPorTipo(tipoId));
    return BaseApiService.parseList(
        res, ValorTipoPropiedad.fromJson, 'Error al obtener valores');
  }

  /// Crear un valor permitido (admin).
  static Future<void> crearValor(int tipoId,
      {required String valor, int? parentValorId, int orden = 0}) async {
    final res = await ApiClient.post(
      ApiConstants.valoresPorTipo(tipoId),
      {
        'valor': valor,
        if (parentValorId != null) 'parentValorId': parentValorId,
        'orden': orden,
      },
      requiresAuth: true,
    );
    BaseApiService.assertSuccess(res,
        successCodes: [200, 201], fallbackMsg: 'Error al crear valor');
  }

  /// Actualizar un valor permitido (admin).
  static Future<void> actualizarValor(int id,
      {required String valor, int orden = 0, bool activo = true}) async {
    final res = await ApiClient.put(
      ApiConstants.valorPropiedad(id),
      {'valor': valor, 'orden': orden, 'activo': activo},
    );
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al actualizar valor');
  }

  /// Desactivar un valor permitido (admin).
  static Future<void> desactivarValor(int id) async {
    final res = await ApiClient.delete(ApiConstants.valorPropiedad(id));
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al desactivar valor');
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
    bool esParqueadero = false,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.tiposPropiedad,
      {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (parentId != null) 'parentId': parentId,
        'esFacturable':  esFacturable,
        'esParqueadero': esParqueadero,
      },
      requiresAuth: true,
    );
    BaseApiService.assertSuccess(res,
        successCodes: [200, 201], fallbackMsg: 'Error al crear tipo');
  }

  /// Actualizar tipo de propiedad (admin)
  static Future<void> actualizarTipo(int id,
      {required String nombre, String? descripcion, bool esFacturable = false, bool esParqueadero = false}) async {
    final res = await ApiClient.put(
      '${ApiConstants.tiposPropiedad}/$id',
      {
        'nombre':       nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'esFacturable':  esFacturable,
        'esParqueadero': esParqueadero,
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

  /// Listar todas las propiedades del conjunto (admin), tipadas para la gestión.
  static Future<List<PropiedadAdmin>> getPropiedadesAdmin() async {
    final res = await ApiClient.get(ApiConstants.propiedades);
    return BaseApiService.parseList(
        res, PropiedadAdmin.fromJson, 'Error al listar propiedades');
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
