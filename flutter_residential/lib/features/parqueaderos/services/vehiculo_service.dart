import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/vehiculo_model.dart';

class VehiculoService {
  // ─── Admin ────────────────────────────────────────────────────────────────

  static Future<List<VehiculoModel>> listarAdmin({bool soloPendientes = false}) async {
    final url = soloPendientes
        ? '${ApiConstants.adminVehiculos}?soloPendientes=true'
        : ApiConstants.adminVehiculos;
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, VehiculoModel.fromJson, 'Error al listar vehículos');
  }

  static Future<VehiculoModel> aprobar(int id) async {
    final res = await ApiClient.put(ApiConstants.adminVehiculoAprobar(id), {});
    return BaseApiService.parseSingle(
      res,
      VehiculoModel.fromJson,
      fallbackMsg: 'Error al aprobar vehículo',
    );
  }

  static Future<VehiculoModel> rechazar(int id, {String? motivo}) async {
    final res = await ApiClient.put(
      ApiConstants.adminVehiculoRechazar(id),
      motivo != null ? {'motivo': motivo} : {},
    );
    return BaseApiService.parseSingle(
      res,
      VehiculoModel.fromJson,
      fallbackMsg: 'Error al rechazar vehículo',
    );
  }

  // ─── Residente ────────────────────────────────────────────────────────────

  static Future<List<VehiculoModel>> misVehiculos(int propiedadId) async {
    final res = await ApiClient.get(
      '${ApiConstants.residenteVehiculos}?propiedadId=$propiedadId',
    );
    return BaseApiService.parseList(res, VehiculoModel.fromJson, 'Error al obtener tus vehículos');
  }

  static Future<VehiculoModel> registrar(
      Map<String, dynamic> data, int propiedadId) async {
    final res = await ApiClient.post(
      '${ApiConstants.residenteVehiculos}?propiedadId=$propiedadId',
      data,
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
      res,
      VehiculoModel.fromJson,
      successCodes: [200, 201],
      fallbackMsg: 'Error al registrar vehículo',
    );
  }

  static Future<void> eliminar(int vehiculoId, int propiedadId) async {
    final res = await ApiClient.delete(
      '${ApiConstants.residenteVehiculoEliminar(vehiculoId)}?propiedadId=$propiedadId',
    );
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al eliminar vehículo');
  }
}
