import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../../vigilancia/models/paquete_model.dart';

/// Paquetería del residente: correspondencia recibida para sus unidades.
class PaqueteResidenteService {
  static Future<List<PaqueteModel>> mios() async {
    final res = await ApiClient.get(ApiConstants.misPaquetes);
    return BaseApiService.parseList(
        res, PaqueteModel.fromJson, 'Error al cargar tus paquetes');
  }
}
