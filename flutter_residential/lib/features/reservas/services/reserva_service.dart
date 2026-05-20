import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/reserva_model.dart';

class ReservaService {
  // ─── Admin: Reservas ───────────────────────────────────────

  static Future<List<ReservaModel>> listarAdmin({String? estado}) async {
    final url = estado == null
        ? ApiConstants.adminReservas
        : '${ApiConstants.adminReservas}?estado=$estado';
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, ReservaModel.fromJson, 'Error al listar reservas');
  }

  static Future<ReservaModel> aprobar(int id, {String? motivo}) async {
    final res = await ApiClient.put(ApiConstants.aprobarReserva(id), {'motivo': motivo});
    return BaseApiService.parseSingle(res, ReservaModel.fromJson,
        fallbackMsg: 'Error al aprobar reserva');
  }

  static Future<ReservaModel> rechazar(int id, String motivo) async {
    final res = await ApiClient.put(ApiConstants.rechazarReserva(id), {'motivo': motivo});
    return BaseApiService.parseSingle(res, ReservaModel.fromJson,
        fallbackMsg: 'Error al rechazar reserva');
  }

  // ─── Admin: Zonas comunes ─────────────────────────────────

  static Future<List<ZonaComunModel>> listarZonasAdmin() async {
    final res = await ApiClient.get(ApiConstants.adminZonasComunes);
    return BaseApiService.parseList(res, ZonaComunModel.fromJson, 'Error al listar zonas');
  }

  static Future<ZonaComunModel> crearZona(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminZonasComunes, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, ZonaComunModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al crear zona');
  }

  static Future<ZonaComunModel> actualizarZona(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put(ApiConstants.actualizarZona(id), data);
    return BaseApiService.parseSingle(res, ZonaComunModel.fromJson,
        fallbackMsg: 'Error al actualizar zona');
  }

  static Future<ZonaComunModel> suspenderZona(int id, String motivo) async {
    final res = await ApiClient.put(ApiConstants.suspenderZona(id), {'motivo': motivo});
    return BaseApiService.parseSingle(res, ZonaComunModel.fromJson,
        fallbackMsg: 'Error al suspender zona');
  }

  static Future<ZonaComunModel> reactivarZona(int id) async {
    final res = await ApiClient.put(ApiConstants.reactivarZona(id), {});
    return BaseApiService.parseSingle(res, ZonaComunModel.fromJson,
        fallbackMsg: 'Error al reactivar zona');
  }

  // ─── Admin: Excepciones ────────────────────────────────────

  static Future<List<ExcepcionZonaComunModel>> listarExcepciones(int zonaId) async {
    final res = await ApiClient.get(ApiConstants.excepcionesZona(zonaId));
    return BaseApiService.parseList(
        res, ExcepcionZonaComunModel.fromJson, 'Error al listar excepciones');
  }

  static Future<ExcepcionZonaComunModel> agregarExcepcion(
      int zonaId, Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.excepcionesZona(zonaId), data, requiresAuth: true);
    return BaseApiService.parseSingle(res, ExcepcionZonaComunModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al agregar excepción');
  }

  static Future<void> eliminarExcepcion(int zonaId, int excId) async {
    final res = await ApiClient.delete(ApiConstants.eliminarExcepcionZona(zonaId, excId));
    BaseApiService.assertSuccess(res, successCodes: [204], fallbackMsg: 'Error al eliminar excepción');
  }

  // ─── Residente ────────────────────────────────────────────

  static Future<List<ZonaComunModel>> zonasActivas() async {
    final res = await ApiClient.get(ApiConstants.residenteZonasComunes);
    return BaseApiService.parseList(res, ZonaComunModel.fromJson, 'Error al listar zonas');
  }

  static Future<ReservaModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.residenteReservas, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, ReservaModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear reserva');
  }

  static Future<List<ReservaModel>> misReservas() async {
    final res = await ApiClient.get(ApiConstants.misReservas);
    return BaseApiService.parseList(res, ReservaModel.fromJson, 'Error al obtener tus reservas');
  }

  static Future<ReservaModel> cancelar(int id) async {
    final res = await ApiClient.put(ApiConstants.cancelarReserva(id), {});
    return BaseApiService.parseSingle(res, ReservaModel.fromJson,
        fallbackMsg: 'Error al cancelar reserva');
  }
}
