import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/acceso_vehicular_model.dart';
import '../models/bitacora_acceso_model.dart';
import '../models/paquete_model.dart';
import '../models/detalle_visita_model.dart';
import '../models/propiedad_opcion_model.dart';

/// Operaciones del rol VIGILANTE contra el backend.
class VigilanciaService {
  // ── Acceso ────────────────────────────────────────────────────────────────

  static Future<AccesoVehicularModel> accesoVehicular(String placa) async {
    final res = await ApiClient.get(ApiConstants.vigilanteAccesoVehicular(placa));
    return BaseApiService.parseSingle(res, AccesoVehicularModel.fromJson,
        fallbackMsg: 'Placa no registrada en el conjunto');
  }

  static Future<BitacoraAccesoModel> accesoPeatonal({
    required int propiedadId,
    String? nombreVisitante,
    String? documento,
    String? motivo,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.vigilanteAccesoPeatonal,
      {
        'propiedadId': propiedadId,
        if (nombreVisitante != null) 'nombreVisitante': nombreVisitante,
        if (documento != null) 'documento': documento,
        if (motivo != null) 'motivo': motivo,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, BitacoraAccesoModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al registrar el ingreso');
  }

  /// Selector paginado de propiedades facturables, con buscador por path corto.
  static Future<PropiedadOpcionPage> buscarPropiedades({
    String? buscar,
    int page = 0,
    int size = 20,
  }) async {
    final res = await ApiClient.get(
        ApiConstants.vigilantePropiedades(buscar: buscar, page: page, size: size));
    return BaseApiService.parseSingle(res, PropiedadOpcionPage.fromJson,
        fallbackMsg: 'Error al cargar propiedades');
  }

  // ── Visitas ───────────────────────────────────────────────────────────────

  /// Consulta (sin mutar) los datos de la visita escaneada.
  static Future<DetalleVisitaModel> consultarVisita(String codigo) async {
    final res = await ApiClient.get(ApiConstants.vigilanteConsultarVisita(codigo));
    return BaseApiService.parseSingle(res, DetalleVisitaModel.fromJson,
        fallbackMsg: 'Código de visita no válido');
  }

  static Future<DetalleVisitaModel> aprobarVisita(int id) async {
    final res = await ApiClient.post(ApiConstants.vigilanteAprobarVisita(id), {},
        requiresAuth: true);
    return BaseApiService.parseSingle(res, DetalleVisitaModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al aprobar la visita');
  }

  static Future<DetalleVisitaModel> rechazarVisita(int id, String motivo) async {
    final res = await ApiClient.post(
        ApiConstants.vigilanteRechazarVisita(id), {'motivo': motivo},
        requiresAuth: true);
    return BaseApiService.parseSingle(res, DetalleVisitaModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al rechazar la visita');
  }

  // ── Paqueteria ──────────────────────────────────────────────────────────

  static Future<List<PaqueteModel>> paquetesPendientes() async {
    final res = await ApiClient.get(ApiConstants.vigilantePaquetesPendientes);
    return BaseApiService.parseList(
        res, PaqueteModel.fromJson, 'Error al listar paquetes');
  }

  static Future<PaqueteModel> registrarPaquete({
    required int propiedadId,
    required String descripcion,
    String? remitente,
    String? transportadora,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.vigilantePaquetes,
      {
        'propiedadId': propiedadId,
        'descripcion': descripcion,
        if (remitente != null) 'remitente': remitente,
        if (transportadora != null) 'transportadora': transportadora,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, PaqueteModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al registrar el paquete');
  }

  static Future<PaqueteModel> entregarPaquete(int id, {String? entregadoA}) async {
    final res = await ApiClient.put(
      ApiConstants.vigilanteEntregarPaquete(id),
      {if (entregadoA != null) 'entregadoA': entregadoA},
    );
    return BaseApiService.parseSingle(res, PaqueteModel.fromJson,
        fallbackMsg: 'Error al entregar el paquete');
  }

  // ── Bitácora ────────────────────────────────────────────────────────────────

  static Future<List<BitacoraAccesoModel>> bitacora({int limite = 50}) async {
    final res = await ApiClient.get(ApiConstants.vigilanteBitacora(limite: limite));
    return BaseApiService.parseList(
        res, BitacoraAccesoModel.fromJson, 'Error al cargar la bitácora');
  }
}
