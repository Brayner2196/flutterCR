import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/pqr_model.dart';

class PqrService {
  static Future<List<PqrModel>> listarAdmin({String? estado}) async {
    final url = estado == null
        ? ApiConstants.adminPqrs
        : '${ApiConstants.adminPqrs}?estado=$estado';
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, PqrModel.fromJson, 'Error al listar PQRs');
  }

  static Future<PqrModel> responder(int id, String respuesta) async {
    final res = await ApiClient.put(ApiConstants.responderPqr(id), {'respuesta': respuesta});
    return BaseApiService.parseSingle(res, PqrModel.fromJson,
        fallbackMsg: 'Error al responder PQR');
  }

  static Future<PqrModel> cambiarEstado(int id, String estado) async {
    final res = await ApiClient.put(ApiConstants.estadoPqr(id), {'estado': estado});
    return BaseApiService.parseSingle(res, PqrModel.fromJson,
        fallbackMsg: 'Error al cambiar estado');
  }

  static Future<List<PqrModel>> misPqrs() async {
    final res = await ApiClient.get(ApiConstants.misPqrs);
    return BaseApiService.parseList(res, PqrModel.fromJson, 'Error al obtener tus PQRs');
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
    return BaseApiService.parseSingle(res, PqrModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear PQR');
  }
}
