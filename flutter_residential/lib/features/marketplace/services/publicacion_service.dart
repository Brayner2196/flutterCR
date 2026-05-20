import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/publicacion_model.dart';

class PublicacionService {
  // ─── Marketplace ──────────────────────────────────────────────

  static Future<List<PublicacionModel>> getMarketplace({
    String? busqueda,
    String? categoria,
  }) async {
    final params = <String, String>{};
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;
    if (categoria != null) params['categoria'] = categoria;

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final res = await ApiClient.get('${ApiConstants.marketplace}$query');
    return BaseApiService.parseList(res, PublicacionModel.fromJson, 'Error al cargar el marketplace');
  }

  // ─── Mis publicaciones ────────────────────────────────────────

  static Future<List<PublicacionModel>> getMisPublicaciones() async {
    final res = await ApiClient.get(ApiConstants.misPublicaciones);
    return BaseApiService.parseList(
        res, PublicacionModel.fromJson, 'Error al obtener tus publicaciones');
  }

  static Future<PublicacionModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.crearPublicacion, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, PublicacionModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al crear la publicación');
  }

  static Future<PublicacionModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put(ApiConstants.actualizarPublicacion(id), data);
    return BaseApiService.parseSingle(res, PublicacionModel.fromJson,
        fallbackMsg: 'Error al actualizar la publicación');
  }

  static Future<PublicacionModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.patch(ApiConstants.estadoPublicacion(id), {'estado': estado});
    return BaseApiService.parseSingle(res, PublicacionModel.fromJson,
        fallbackMsg: 'Error al cambiar el estado');
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete(ApiConstants.eliminarPublicacion(id));
    BaseApiService.assertSuccess(res, successCodes: [204], fallbackMsg: 'Error al eliminar la publicación');
  }

  // ─── Admin ────────────────────────────────────────────────────

  static Future<List<PublicacionModel>> getTodasAdmin() async {
    final res = await ApiClient.get(ApiConstants.adminPublicaciones);
    return BaseApiService.parseList(res, PublicacionModel.fromJson, 'Error al cargar publicaciones');
  }

  static Future<void> eliminarAdmin(int id) async {
    final res = await ApiClient.delete(ApiConstants.eliminarPublicacionAdmin(id));
    BaseApiService.assertSuccess(res, successCodes: [204], fallbackMsg: 'Error al eliminar la publicación');
  }
}
