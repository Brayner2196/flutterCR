import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/configuracion_parqueadero_model.dart';
import '../models/parqueadero_model.dart';

class ParqueaderoService {
  // ─── Admin: Configuración ──────────────────────────────────────────────────

  static Future<ConfiguracionParqueaderoModel> obtenerConfig() async {
    final res = await ApiClient.get(ApiConstants.adminParqueaderosConfig);
    return BaseApiService.parseSingle(
      res,
      ConfiguracionParqueaderoModel.fromJson,
      fallbackMsg: 'Error al obtener configuración de parqueaderos',
    );
  }

  static Future<ConfiguracionParqueaderoModel> guardarConfig(
      Map<String, dynamic> data) async {
    final res = await ApiClient.put(ApiConstants.adminParqueaderosConfig, data);
    return BaseApiService.parseSingle(
      res,
      ConfiguracionParqueaderoModel.fromJson,
      fallbackMsg: 'Error al guardar configuración',
    );
  }

  // ─── Admin: Parqueaderos ──────────────────────────────────────────────────

  static Future<List<ParqueaderoModel>> listarAdmin() async {
    final res = await ApiClient.get(ApiConstants.adminParqueaderos);
    return BaseApiService.parseList(
      res,
      ParqueaderoModel.fromJson,
      'Error al listar parqueaderos',
    );
  }

  /// Crea varios parqueaderos privados en una sola llamada.
  /// Retorna el mapa crudo del servidor con {creados, duplicados, items}.
  static Future<Map<String, dynamic>> crearBulk(
      List<String> identificadores) async {
    final body = {
      'items': identificadores.map((id) => {'identificador': id}).toList(),
    };
    final res = await ApiClient.post(
      ApiConstants.adminParqueaderosBulk,
      body,
      requiresAuth: true,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(
        message: 'Error al crear parqueaderos',
        statusCode: res.statusCode,
      );
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<ParqueaderoModel> asignarPropiedad(
      int parqueaderoId, int? propiedadId) async {
    final res = await ApiClient.patch(
      ApiConstants.adminParqueaderoAsignarPropiedad(parqueaderoId),
      {'propiedadId': propiedadId},
    );
    return BaseApiService.parseSingle(
      res,
      ParqueaderoModel.fromJson,
      fallbackMsg: 'Error al asignar propiedad',
    );
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete(ApiConstants.adminParqueaderoEliminar(id));
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204],
        fallbackMsg: 'Error al eliminar parqueadero');
  }

  // ─── Residente: Mis parqueaderos ──────────────────────────────────────────

  static Future<List<ParqueaderoModel>> misParqueaderos(int propiedadId) async {
    final res = await ApiClient.get(
      '${ApiConstants.residenteMisParqueaderos}?propiedadId=$propiedadId',
    );
    return BaseApiService.parseList(
      res,
      ParqueaderoModel.fromJson,
      'Error al obtener tus parqueaderos',
    );
  }

  static Future<ParqueaderoModel> cambiarVehiculo(
      int parqueaderoId, int? vehiculoId, int propiedadId) async {
    final res = await ApiClient.patch(
      '${ApiConstants.residenteParqueaderoCambiarVehiculo(parqueaderoId)}?propiedadId=$propiedadId',
      {'vehiculoId': vehiculoId},
    );
    return BaseApiService.parseSingle(
      res,
      ParqueaderoModel.fromJson,
      fallbackMsg: 'Error al asignar vehículo',
    );
  }
}
