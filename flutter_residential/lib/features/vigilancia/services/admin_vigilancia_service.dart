import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/bitacora_acceso_model.dart';
import '../models/config_vigilancia_model.dart';

/// Parametrización y reportes de vigilancia (solo TENANT_ADMIN).
class AdminVigilanciaService {
  static Future<ConfigVigilanciaModel> obtenerConfig() async {
    final res = await ApiClient.get(ApiConstants.adminVigilanciaConfig);
    return BaseApiService.parseSingle(res, ConfigVigilanciaModel.fromJson,
        fallbackMsg: 'Error al cargar la configuración');
  }

  static Future<ConfigVigilanciaModel> actualizarConfig(
      ConfigVigilanciaModel cfg) async {
    final res = await ApiClient.put(ApiConstants.adminVigilanciaConfig, cfg.toJson());
    return BaseApiService.parseSingle(res, ConfigVigilanciaModel.fromJson,
        fallbackMsg: 'Error al guardar la configuración');
  }

  static Future<List<BitacoraAccesoModel>> bitacora({String? desde, String? hasta}) async {
    final res = await ApiClient.get(
        ApiConstants.adminVigilanciaBitacora(desde: desde, hasta: hasta));
    return BaseApiService.parseList(
        res, BitacoraAccesoModel.fromJson, 'Error al cargar la bitácora');
  }
}
