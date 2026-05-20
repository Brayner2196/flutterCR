import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/configuracion_mora_model.dart';

class MoraService {
  /// Configuración de mora activa. Null si nunca se ha configurado.
  static Future<ConfiguracionMoraModel?> obtenerActiva() async {
    try {
      final res = await ApiClient.get(ApiConstants.adminMora, requiresAuth: true);
      if (res.statusCode == 200) {
        return ConfiguracionMoraModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Histórico completo de configuraciones de mora.
  static Future<List<ConfiguracionMoraModel>> listarHistorico() async {
    try {
      final res = await ApiClient.get(ApiConstants.adminMoraHistorico, requiresAuth: true);
      if (res.statusCode == 200) {
        return BaseApiService.parseList(
            res, ConfiguracionMoraModel.fromJson, 'Error al obtener historial');
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Crea nueva configuración de mora (desactiva la anterior).
  static Future<ConfiguracionMoraModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminMora, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, ConfiguracionMoraModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al guardar configuración de mora');
  }
}
