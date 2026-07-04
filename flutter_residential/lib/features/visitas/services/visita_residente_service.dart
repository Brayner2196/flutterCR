import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../../vigilancia/models/visita_model.dart';

/// Operaciones de visitas para el residente (crear QR, listar, cancelar).
class VisitaResidenteService {
  static Future<VisitaModel> crear({
    required int propiedadId,
    required String nombreVisitante,
    String? documento,
    String? placa,
    String? motivo,
    int cantidadPersonas = 1,
    String? acompanantes,
    String? franjaDesde,
    String? franjaHasta,
    int? validezHoras,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.residenteVisitas,
      {
        'propiedadId': propiedadId,
        'nombreVisitante': nombreVisitante,
        'cantidadPersonas': cantidadPersonas,
        if (documento != null) 'documento': documento,
        if (placa != null) 'placa': placa,
        if (motivo != null) 'motivo': motivo,
        if (acompanantes != null) 'acompanantes': acompanantes,
        if (franjaDesde != null) 'franjaDesde': franjaDesde,
        if (franjaHasta != null) 'franjaHasta': franjaHasta,
        if (validezHoras != null) 'validezHoras': validezHoras,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, VisitaModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear la visita');
  }

  static Future<List<VisitaModel>> mias() async {
    final res = await ApiClient.get(ApiConstants.misVisitas);
    return BaseApiService.parseList(
        res, VisitaModel.fromJson, 'Error al cargar tus visitas');
  }

  static Future<VisitaModel> cancelar(int id) async {
    final res = await ApiClient.put(ApiConstants.cancelarVisita(id), {});
    return BaseApiService.parseSingle(res, VisitaModel.fromJson,
        fallbackMsg: 'Error al cancelar la visita');
  }
}
