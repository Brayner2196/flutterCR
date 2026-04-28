import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/pqr_model.dart';

class PqrService {
  static Future<List<PqrModel>> listarAdmin({String? estado}) async {
    final url = estado == null
        ? ApiConstants.adminPqrs
        : '${ApiConstants.adminPqrs}?estado=$estado';
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => PqrModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al listar PQRs'));
  }

  static Future<PqrModel> responder(int id, String respuesta) async {
    final res = await ApiClient.put(
        ApiConstants.responderPqr(id), {'respuesta': respuesta});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return PqrModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al responder PQR'));
  }

  static Future<PqrModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(
        ApiConstants.estadoPqr(id), {'estado': estado});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return PqrModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cambiar estado'));
  }

  static Future<List<PqrModel>> misPqrs() async {
    final res = await ApiClient.get(ApiConstants.misPqrs);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => PqrModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al obtener tus PQRs'));
  }

  static Future<PqrModel> crear({
    required String tipo,
    required String asunto,
    required String descripcion,
    int? propiedadId,
  }) async {
    final res = await ApiClient.post(
        ApiConstants.residentePqrs,
        {
          'tipo': tipo,
          'asunto': asunto,
          'descripcion': descripcion,
          if (propiedadId != null) 'propiedadId': propiedadId,
        },
        requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return PqrModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al crear PQR'));
  }

  static String _msg(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return fallback;
  }
}
