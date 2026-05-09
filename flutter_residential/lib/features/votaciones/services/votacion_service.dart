import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/votacion_model.dart';

class VotacionService {
  // ─── Admin ───────────────────────────────────────────────────────────────

  static Future<List<VotacionModel>> listarAdmin({String? estado}) async {
    final url = estado != null
        ? '${ApiConstants.adminVotaciones}?estado=$estado'
        : ApiConstants.adminVotaciones;
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => VotacionModel.fromJson(e)).toList();
    }
    throw Exception(_msg(body, 'Error al listar votaciones'));
  }

  static Future<VotacionModel> obtenerAdmin(int id) async {
    final res = await ApiClient.get('${ApiConstants.adminVotaciones}/$id');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Votación no encontrada'));
  }

  static Future<VotacionModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminVotaciones, data, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al crear votación'));
  }

  static Future<VotacionModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('${ApiConstants.adminVotaciones}/$id', data);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al actualizar votación'));
  }

  static Future<VotacionModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(ApiConstants.estadoVotacion(id), {'estado': estado});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al cambiar estado'));
  }

  static Future<VotacionModel> resultados(int id) async {
    final res = await ApiClient.get(ApiConstants.resultadosVotacion(id));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al obtener resultados'));
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  static Future<List<VotacionModel>> listarResidente() async {
    final res = await ApiClient.get(ApiConstants.residenteVotaciones);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => VotacionModel.fromJson(e)).toList();
    }
    throw Exception(_msg(body, 'Error al listar votaciones'));
  }

  static Future<VotacionModel> detalleResidente(int id) async {
    final res = await ApiClient.get('${ApiConstants.residenteVotaciones}/$id');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al obtener votación'));
  }

  static Future<VotacionModel> votar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.votarEnVotacion(id), data, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return VotacionModel.fromJson(body);
    throw Exception(_msg(body, 'Error al registrar voto'));
  }

  static String _msg(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return fallback;
  }
}
