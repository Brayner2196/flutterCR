import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/solicitud_model.dart';

class SolicitudService {
  // ─── Crear solicitud (comprador) ──────────────────────────────
  /// [tipo] DOMICILIO | RECOGIDA
  static Future<SolicitudModel> crear({
    required int publicacionId,
    required String tipo,
    required int cantidad,
    String? notas,
  }) async {
    final data = <String, dynamic>{
      'publicacionId': publicacionId,
      'tipo': tipo,
      'cantidad': cantidad,
      if (notas != null && notas.trim().isNotEmpty) 'notas': notas.trim(),
    };

    final res = await ApiClient.post(ApiConstants.crearSolicitud, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, SolicitudModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al enviar la solicitud');
  }

  // ─── Solicitudes enviadas por el comprador ────────────────────
  static Future<List<SolicitudModel>> getMisEnviadas() async {
    final res = await ApiClient.get(ApiConstants.misSolicitudesEnviadas);
    return BaseApiService.parseList(
        res, SolicitudModel.fromJson, 'Error al obtener solicitudes enviadas');
  }

  // ─── Solicitudes recibidas por el vendedor ────────────────────
  static Future<List<SolicitudModel>> getMisRecibidas() async {
    final res = await ApiClient.get(ApiConstants.misSolicitudesRecibidas);
    return BaseApiService.parseList(
        res, SolicitudModel.fromJson, 'Error al obtener solicitudes recibidas');
  }

  // ─── Actualizar estado (vendedor acepta/rechaza) ──────────────
  static Future<SolicitudModel> actualizarEstado(int id, String estado) async {
    final res = await ApiClient.patch(ApiConstants.actualizarEstadoSolicitud(id), {'estado': estado});
    return BaseApiService.parseSingle(res, SolicitudModel.fromJson,
        fallbackMsg: 'Error al actualizar el estado');
  }
}
