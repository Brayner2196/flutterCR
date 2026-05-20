import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/usuario_response.dart';

class UsuarioService {
  static Future<List<UsuarioResponse>> listarTodos() async {
    final res = await ApiClient.get(ApiConstants.usuarios);
    return BaseApiService.parseList(
        res, UsuarioResponse.fromJson, 'Error al cargar usuarios');
  }

  static Future<UsuarioResponse> crear(Map<String, dynamic> data) async {
    final res =
        await ApiClient.post(ApiConstants.usuarios, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, UsuarioResponse.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear usuario');
  }

  /// [rolDestino] puede ser 'PROPIETARIO' (default) o 'INQUILINO'
  static Future<UsuarioResponse> aprobar(int id,
      {String rolDestino = 'PROPIETARIO'}) async {
    final res = await ApiClient.put(
        '${ApiConstants.usuarios}/$id/aprobar?rolDestino=$rolDestino', {});
    return BaseApiService.parseSingle(res, UsuarioResponse.fromJson,
        fallbackMsg: 'Error al aprobar usuario');
  }

  static Future<UsuarioResponse> rechazar(int id) async {
    final res =
        await ApiClient.put('${ApiConstants.usuarios}/$id/rechazar', {});
    return BaseApiService.parseSingle(res, UsuarioResponse.fromJson,
        fallbackMsg: 'Error al rechazar usuario');
  }

  static Future<UsuarioResponse> buscarPorId(int id) async {
    final res = await ApiClient.get('${ApiConstants.usuarios}/$id');
    return BaseApiService.parseSingle(res, UsuarioResponse.fromJson,
        fallbackMsg: 'Error al buscar usuario');
  }

  static Future<UsuarioResponse> actualizar(
      int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('${ApiConstants.usuarios}/$id', data);
    return BaseApiService.parseSingle(res, UsuarioResponse.fromJson,
        fallbackMsg: 'Error al actualizar usuario');
  }

  static Future<void> activar(int id) async {
    final res = await ApiClient.patch(ApiConstants.activarUsuario(id));
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al activar usuario');
  }

  static Future<void> desactivar(int id) async {
    final res = await ApiClient.patch(ApiConstants.desactivarUsuario(id));
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al desactivar usuario');
  }

  static Future<void> cambiarRol(int id, String rol) async {
    final res = await ApiClient.patch(
        '${ApiConstants.cambiarRolUsuario(id)}?rol=$rol');
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al cambiar rol');
  }
}
