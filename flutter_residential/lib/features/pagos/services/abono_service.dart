import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/abono_model.dart';
import '../models/simular_abono_model.dart';
import '../models/saldo_favor_model.dart';

class AbonoService {
  // ─── Residente ───────────────────────────────────

  static Future<AbonoModel> registrarAbono(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.misAbonos, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, AbonoModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al registrar abono');
  }

  static Future<List<AbonoModel>> getMisAbonos() async {
    final res = await ApiClient.get(ApiConstants.misAbonos);
    return BaseApiService.parseList(res, AbonoModel.fromJson, 'Error al obtener abonos');
  }

  static Future<SimularAbonoModel> simular(int propiedadId, double monto) async {
    final url = '${ApiConstants.simularAbono}?propiedadId=$propiedadId&monto=$monto';
    final res = await ApiClient.get(url);
    return BaseApiService.parseSingle(res, SimularAbonoModel.fromJson,
        fallbackMsg: 'Error al simular abono');
  }

  static Future<SaldoFavorModel> getSaldoFavor(int propiedadId) async {
    final res = await ApiClient.get('${ApiConstants.saldoFavor}?propiedadId=$propiedadId');
    return BaseApiService.parseSingle(res, SaldoFavorModel.fromJson,
        fallbackMsg: 'Error al obtener saldo a favor');
  }

  // ─── Admin ──────────────────────────────────────

  static Future<List<AbonoModel>> listarAbonosAdmin(
      {String estado = 'PENDIENTE_VERIFICACION'}) async {
    final res = await ApiClient.get(
        '${ApiConstants.adminAbonos}?estado=$estado', requiresAuth: true);
    return BaseApiService.parseList(res, AbonoModel.fromJson, 'Error al listar abonos');
  }

  static Future<AbonoModel> verificarAbono(int id, {String? notas}) async {
    final res = await ApiClient.put(ApiConstants.verificarAbono(id), {'notas': notas});
    return BaseApiService.parseSingle(res, AbonoModel.fromJson,
        fallbackMsg: 'Error al verificar abono');
  }

  static Future<AbonoModel> rechazarAbono(int id, String motivo) async {
    final res = await ApiClient.put(ApiConstants.rechazarAbono(id), {'motivoRechazo': motivo});
    return BaseApiService.parseSingle(res, AbonoModel.fromJson,
        fallbackMsg: 'Error al rechazar abono');
  }
}
