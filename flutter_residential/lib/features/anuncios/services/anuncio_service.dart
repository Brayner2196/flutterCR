import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/anuncio_model.dart';

class AnuncioService {
  // ─── Admin ───────────────────────────────────────────────────────────────

  static Future<List<AnuncioModel>> listarAdmin({String? estado}) async {
    final url = estado != null
        ? '${ApiConstants.adminAnuncios}?estado=$estado'
        : ApiConstants.adminAnuncios;
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, AnuncioModel.fromJson, 'Error al listar anuncios');
  }

  static Future<AnuncioModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminAnuncios, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, AnuncioModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear anuncio');
  }

  static Future<AnuncioModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('${ApiConstants.adminAnuncios}/$id', data);
    return BaseApiService.parseSingle(res, AnuncioModel.fromJson,
        fallbackMsg: 'Error al actualizar anuncio');
  }

  static Future<AnuncioModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(ApiConstants.estadoAnuncio(id), {'estado': estado});
    return BaseApiService.parseSingle(res, AnuncioModel.fromJson,
        fallbackMsg: 'Error al cambiar estado');
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete('${ApiConstants.adminAnuncios}/$id');
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al eliminar anuncio');
  }

  static Future<List<AnuncioVistaModel>> listarVistas(int id) async {
    final res = await ApiClient.get(ApiConstants.vistasAnuncio(id));
    return BaseApiService.parseList(res, AnuncioVistaModel.fromJson, 'Error al obtener vistas');
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  static Future<List<AnuncioModel>> listarResidente() async {
    final res = await ApiClient.get(ApiConstants.residenteAnuncios);
    return BaseApiService.parseList(res, AnuncioModel.fromJson, 'Error al listar anuncios');
  }

  static Future<AnuncioModel> marcarVisto(int id) async {
    final res = await ApiClient.post(ApiConstants.marcarAnuncioVisto(id), {}, requiresAuth: true);
    return BaseApiService.parseSingle(res, AnuncioModel.fromJson,
        fallbackMsg: 'Error al marcar como visto');
  }
}
