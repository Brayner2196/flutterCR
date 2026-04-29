import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/abono_model.dart';
import '../models/simular_abono_model.dart';
import '../models/saldo_favor_model.dart';

class AbonoService {
  // ─── Residente ───────────────────────────────────

  static Future<AbonoModel> registrarAbono(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.misAbonos, data, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return AbonoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al registrar abono');
  }

  static Future<List<AbonoModel>> getMisAbonos() async {
    final res = await ApiClient.get(ApiConstants.misAbonos);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => AbonoModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener abonos');
  }

  static Future<SimularAbonoModel> simular(int propiedadId, double monto) async {
    final url = '${ApiConstants.simularAbono}?propiedadId=$propiedadId&monto=$monto';
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return SimularAbonoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al simular abono');
  }

  static Future<SaldoFavorModel> getSaldoFavor(int propiedadId) async {
    final res = await ApiClient.get('${ApiConstants.saldoFavor}?propiedadId=$propiedadId');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return SaldoFavorModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al obtener saldo a favor');
  }

  // ─── Admin ──────────────────────────────────────

  static Future<List<AbonoModel>> listarAbonosAdmin(
      {String estado = 'PENDIENTE_VERIFICACION'}) async {
    final res = await ApiClient.get(
        '${ApiConstants.adminAbonos}?estado=$estado', requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => AbonoModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar abonos');
  }

  static Future<AbonoModel> verificarAbono(int id, {String? notas}) async {
    final res = await ApiClient.put(
        ApiConstants.verificarAbono(id), {'notas': notas});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return AbonoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al verificar abono');
  }

  static Future<AbonoModel> rechazarAbono(int id, String motivo) async {
    final res = await ApiClient.put(
        ApiConstants.rechazarAbono(id), {'motivoRechazo': motivo});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return AbonoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al rechazar abono');
  }
}
