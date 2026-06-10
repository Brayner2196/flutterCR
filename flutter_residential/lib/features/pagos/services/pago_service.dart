import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/pago_model.dart';

class PagoService {
  // ─── Residente ───────────────────────────────────

  static Future<List<PagoModel>> getMisPagos({int? propiedadId}) async {
    String url = ApiConstants.misPagos;
    if (propiedadId != null) url += '?propiedadId=$propiedadId';
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, PagoModel.fromJson, 'Error al obtener pagos');
  }

  // ─── Admin ──────────────────────────────────────

  static Future<List<PagoModel>> listarPagosAdmin(
      {String estado = 'PENDIENTE_VERIFICACION'}) async {
    final res = await ApiClient.get(
        '${ApiConstants.adminPagos}?estado=$estado',
        requiresAuth: true);
    return BaseApiService.parseList(res, PagoModel.fromJson, 'Error al listar pagos');
  }

  static Future<PagoModel> verificarPago(int id, {String? notas}) async {
    final res = await ApiClient.put(ApiConstants.verificarPago(id), {'notas': notas});
    return BaseApiService.parseSingle(res, PagoModel.fromJson,
        fallbackMsg: 'Error al verificar pago');
  }

  static Future<PagoModel> rechazarPago(int id, String motivo) async {
    final res = await ApiClient.put(ApiConstants.rechazarPago(id), {'motivoRechazo': motivo});
    return BaseApiService.parseSingle(res, PagoModel.fromJson,
        fallbackMsg: 'Error al rechazar pago');
  }
}
