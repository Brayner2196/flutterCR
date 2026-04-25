import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/pago_model.dart';

class PagoService {
  // ─── Residente ───────────────────────────────────

  static Future<PagoModel> registrarPago(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.misPagos, data);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return PagoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al registrar pago');
  }

  static Future<List<PagoModel>> getMisPagos() async {
    final res = await ApiClient.get(ApiConstants.misPagos);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => PagoModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener pagos');
  }

  // ─── Admin ──────────────────────────────────────

  static Future<List<PagoModel>> listarPagosAdmin(
      {String estado = 'PENDIENTE_VERIFICACION'}) async {
    final res = await ApiClient.get('${ApiConstants.adminPagos}?estado=$estado');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => PagoModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar pagos');
  }

  static Future<PagoModel> verificarPago(int id, {String? notas}) async {
    final res = await ApiClient.put(
        ApiConstants.verificarPago(id), {'notas': notas});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return PagoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al verificar pago');
  }

  static Future<PagoModel> rechazarPago(int id, String motivo) async {
    final res = await ApiClient.put(
        ApiConstants.rechazarPago(id), {'motivoRechazo': motivo});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return PagoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al rechazar pago');
  }
}
