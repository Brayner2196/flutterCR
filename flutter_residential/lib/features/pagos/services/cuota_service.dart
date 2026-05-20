import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/configuracion_cuota_model.dart';

class CuotaService {
  static Future<List<ConfiguracionCuotaModel>> listar() async {
    final res = await ApiClient.get(ApiConstants.adminCuotas);
    return BaseApiService.parseList(res, ConfiguracionCuotaModel.fromJson, 'Error al listar cuotas');
  }

  static Future<ConfiguracionCuotaModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminCuotas, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, ConfiguracionCuotaModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al crear cuota');
  }

  static Future<void> desactivar(int id) async {
    final res = await ApiClient.put(ApiConstants.desactivarCuota(id), {});
    BaseApiService.assertSuccess(res, successCodes: [204], fallbackMsg: 'Error al desactivar cuota');
  }

  /// Histórico completo: activas + inactivas, ordenadas de más reciente a más antigua.
  static Future<List<ConfiguracionCuotaModel>> listarTodas() async {
    try {
      final res = await ApiClient.get(ApiConstants.adminCuotasHistorico, requiresAuth: true);
      if (res.statusCode == 200) {
        return BaseApiService.parseList(
            res, ConfiguracionCuotaModel.fromJson, 'Error al listar historial');
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
