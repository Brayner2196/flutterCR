import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/votacion_model.dart';

class VotacionService {
  // ─── Admin ───────────────────────────────────────────────────────────────

  static Future<List<VotacionModel>> listarAdmin({String? estado}) async {
    final url = estado != null
        ? '${ApiConstants.adminVotaciones}?estado=$estado'
        : ApiConstants.adminVotaciones;
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, VotacionModel.fromJson, 'Error al listar votaciones');
  }

  static Future<VotacionModel> obtenerAdmin(int id) async {
    final res = await ApiClient.get('${ApiConstants.adminVotaciones}/$id');
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Votación no encontrada');
  }

  static Future<VotacionModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminVotaciones, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear votación');
  }

  static Future<VotacionModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('${ApiConstants.adminVotaciones}/$id', data);
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Error al actualizar votación');
  }

  static Future<VotacionModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(ApiConstants.estadoVotacion(id), {'estado': estado});
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Error al cambiar estado');
  }

  static Future<VotacionModel> resultados(int id) async {
    final res = await ApiClient.get(ApiConstants.resultadosVotacion(id));
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Error al obtener resultados');
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  static Future<List<VotacionModel>> listarResidente() async {
    final res = await ApiClient.get(ApiConstants.residenteVotaciones);
    return BaseApiService.parseList(res, VotacionModel.fromJson, 'Error al listar votaciones');
  }

  static Future<VotacionModel> detalleResidente(int id) async {
    final res = await ApiClient.get('${ApiConstants.residenteVotaciones}/$id');
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Error al obtener votación');
  }

  static Future<VotacionModel> votar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.votarEnVotacion(id), data, requiresAuth: true);
    return BaseApiService.parseSingle(res, VotacionModel.fromJson,
        fallbackMsg: 'Error al registrar voto');
  }
}
