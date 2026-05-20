import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/pago_model.dart';

class PagoService {
  // ─── Residente ───────────────────────────────────

  static Future<PagoModel> registrarPago(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.misPagos, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, PagoModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al registrar pago');
  }

  static Future<List<PagoModel>> getMisPagos() async {
    final res = await ApiClient.get(ApiConstants.misPagos);
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
