import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/anuncio_model.dart';

class AnuncioService {
  // ─── Admin ───────────────────────────────────────────────────────────────

  static Future<List<AnuncioModel>> listarAdmin({String? estado}) async {
    final url = estado != null
        ? '${ApiConstants.adminAnuncios}?estado=$estado'
        : ApiConstants.adminAnuncios;
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => AnuncioModel.fromJson(e)).toList();
    }
    throw Exception(_msg(body, 'Error al listar anuncios'));
  }

  static Future<AnuncioModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminAnuncios, data, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AnuncioModel.fromJson(body);
    }
    throw Exception(_msg(body, 'Error al crear anuncio'));
  }

  static Future<AnuncioModel> actualizar(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('${ApiConstants.adminAnuncios}/$id', data);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return AnuncioModel.fromJson(body);
    throw Exception(_msg(body, 'Error al actualizar anuncio'));
  }

  static Future<AnuncioModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(ApiConstants.estadoAnuncio(id), {'estado': estado});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return AnuncioModel.fromJson(body);
    throw Exception(_msg(body, 'Error al cambiar estado'));
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete('${ApiConstants.adminAnuncios}/$id');
    if (res.statusCode != 204 && res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(_msg(body, 'Error al eliminar anuncio'));
    }
  }

  static Future<List<AnuncioVistaModel>> listarVistas(int id) async {
    final res = await ApiClient.get(ApiConstants.vistasAnuncio(id));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => AnuncioVistaModel.fromJson(e)).toList();
    }
    throw Exception(_msg(body, 'Error al obtener vistas'));
  }

  // ─── Residente ───────────────────────────────────────────────────────────

  static Future<List<AnuncioModel>> listarResidente() async {
    final res = await ApiClient.get(ApiConstants.residenteAnuncios);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => AnuncioModel.fromJson(e)).toList();
    }
    throw Exception(_msg(body, 'Error al listar anuncios'));
  }

  static Future<AnuncioModel> marcarVisto(int id) async {
    final res = await ApiClient.post(ApiConstants.marcarAnuncioVisto(id), {}, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return AnuncioModel.fromJson(body);
    throw Exception(_msg(body, 'Error al marcar como visto'));
  }

  static String _msg(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return fallback;
  }
}
