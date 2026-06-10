import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../../pqr/models/pqr_model.dart';
import '../models/consejo_estadisticas_model.dart';
import '../models/miembro_consejo_model.dart';

class ConsejoService {
  /// Directorio público del consejo — accesible por todos los residentes.
  static Future<List<MiembroConsejoModel>> listarDirectorio() async {
    final res = await ApiClient.get(ApiConstants.consejoMiembros);
    return BaseApiService.parseList(
      res,
      MiembroConsejoModel.fromJson,
      'Error al obtener directorio del consejo',
    );
  }

  /// PQRs del conjunto vistas por el consejo (requiere CONSEJERO o TENANT_ADMIN).
  static Future<List<PqrModel>> listarPqrs({String? estado}) async {
    final res = await ApiClient.get(ApiConstants.consejoPqrs(estado));
    return BaseApiService.parseList(
      res,
      PqrModel.fromJson,
      'Error al obtener PQRs del consejo',
    );
  }

  /// Estadísticas agregadas para el rango [desde, hasta] (yyyy-MM-dd).
  /// Si no se pasan fechas, el backend usa los últimos 30 días.
  static Future<ConsejoEstadisticasModel> listarEstadisticas({
    String? desde,
    String? hasta,
  }) async {
    final res = await ApiClient.get(
      ApiConstants.consejoEstadisticas(desde: desde, hasta: hasta),
    );
    if (res.statusCode == 200) {
      return ConsejoEstadisticasModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al obtener estadísticas (${res.statusCode})');
  }
}
