import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/gasto_registrado_model.dart';
import '../models/presupuesto_model.dart';

class PresupuestoService {
  // ── Admin ─────────────────────────────────────────────────────────

  static Future<List<PresupuestoModel>> listarAdmin() async {
    final res = await ApiClient.get(ApiConstants.adminPresupuestos, requiresAuth: true);
    return BaseApiService.parseList(res, PresupuestoModel.fromJson, 'Error al listar presupuestos');
  }

  static Future<PresupuestoModel> detalleAdmin(int id) async {
    final res = await ApiClient.get(ApiConstants.adminPresupuesto(id), requiresAuth: true);
    return BaseApiService.parseSingle(res, PresupuestoModel.fromJson,
        fallbackMsg: 'Error al obtener presupuesto');
  }

  static Future<PresupuestoModel> crear(Map<String, dynamic> body) async {
    final res = await ApiClient.post(ApiConstants.adminPresupuestos, body, requiresAuth: true);
    return BaseApiService.parseSingle(res, PresupuestoModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al crear presupuesto');
  }

  static Future<PresupuestoModel> actualizar(int id, Map<String, dynamic> body) async {
    final res = await ApiClient.put(ApiConstants.adminPresupuesto(id), body);
    return BaseApiService.parseSingle(res, PresupuestoModel.fromJson,
        fallbackMsg: 'Error al actualizar presupuesto');
  }

  static Future<PresupuestoModel> toggleActivo(int id, {required bool activo}) async {
    final res = await ApiClient.patch(
      ApiConstants.adminPresupuestoToggleActivo(id),
      {'activo': activo},
    );
    return BaseApiService.parseSingle(res, PresupuestoModel.fromJson,
        fallbackMsg: 'Error al cambiar estado');
  }

  static Future<GastoRegistradoModel> registrarGasto(
      int presupuestoId, Map<String, dynamic> body) async {
    final res = await ApiClient.post(
        ApiConstants.adminPresupuestoGastos(presupuestoId), body,
        requiresAuth: true);
    return BaseApiService.parseSingle(res, GastoRegistradoModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al registrar gasto');
  }

  static Future<void> eliminarGasto(int presupuestoId, int gastoId) async {
    await ApiClient.delete(
        ApiConstants.adminEliminarGasto(presupuestoId, gastoId));
  }

  // ── Residente ─────────────────────────────────────────────────────

  static Future<PresupuestoModel?> presupuestoActivo() async {
    final res = await ApiClient.get(ApiConstants.residentePresupuestoActivo, requiresAuth: true);
    if (res.statusCode == 404) return null;
    return BaseApiService.parseSingle(res, PresupuestoModel.fromJson,
        fallbackMsg: 'Error al obtener presupuesto activo');
  }

  static Future<List<PresupuestoModel>> listarResidente() async {
    final res = await ApiClient.get(ApiConstants.residentePresupuestos, requiresAuth: true);
    return BaseApiService.parseList(res, PresupuestoModel.fromJson, 'Error al listar presupuestos');
  }
}
