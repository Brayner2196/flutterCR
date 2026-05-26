import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/configuracion_plan_pago_model.dart';
import '../models/cuota_plan_model.dart';
import '../models/plan_pago_model.dart';

class PlanPagoService {
  // ── Configuración (admin y residente) ─────────────────────────────

  static Future<ConfiguracionPlanPagoModel> obtenerConfigAdmin() async {
    final res = await ApiClient.get(
        ApiConstants.adminPlanPagoConfig, requiresAuth: true);
    return BaseApiService.parseSingle(
        res, ConfiguracionPlanPagoModel.fromJson,
        fallbackMsg: 'Error al obtener configuración');
  }

  static Future<ConfiguracionPlanPagoModel> guardarConfig(
      ConfiguracionPlanPagoModel config) async {
    final res = await ApiClient.put(
        ApiConstants.adminPlanPagoConfig, config.toJson());
    return BaseApiService.parseSingle(
        res, ConfiguracionPlanPagoModel.fromJson,
        fallbackMsg: 'Error al guardar configuración');
  }

  static Future<ConfiguracionPlanPagoModel> obtenerConfigResidente() async {
    final res = await ApiClient.get(
        ApiConstants.residentePlanPagoConfig, requiresAuth: true);
    return BaseApiService.parseSingle(
        res, ConfiguracionPlanPagoModel.fromJson,
        fallbackMsg: 'Error al obtener configuración');
  }

  // ── Admin ─────────────────────────────────────────────────────────

  static Future<List<PlanPagoModel>> listarAdmin({String? estado}) async {
    final url = estado != null
        ? '${ApiConstants.adminPlanesPago}?estado=$estado'
        : ApiConstants.adminPlanesPago;
    final res = await ApiClient.get(url, requiresAuth: true);
    return BaseApiService.parseList(
        res, PlanPagoModel.fromJson, 'Error al listar planes');
  }

  static Future<PlanPagoModel> detalle(int id) async {
    final res = await ApiClient.get(
        ApiConstants.adminPlanPago(id), requiresAuth: true);
    return BaseApiService.parseSingle(
        res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al obtener el plan');
  }

  static Future<PlanPagoModel> decidir(
      int id, bool aprobar, {String? motivoRechazo, String? nota}) async {
    final res = await ApiClient.post(
      ApiConstants.adminDecidirPlan(id),
      {
        'aprobar': aprobar,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
        if (nota != null) 'notaAdmin': nota,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
        res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al procesar la decisión');
  }

  static Future<CuotaPlanModel> marcarCuotaPagada(
      int planId, int cuotaId, {String? nota}) async {
    final body = nota != null ? {'nota': nota} : <String, dynamic>{};
    final res = await ApiClient.post(
      ApiConstants.adminMarcarCuotaPagada(planId, cuotaId),
      body,
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
        res, CuotaPlanModel.fromJson,
        fallbackMsg: 'Error al marcar cuota');
  }

  static Future<PlanPagoModel> cancelarPlan(int id, {String? nota}) async {
    final body = nota != null ? {'nota': nota} : <String, dynamic>{};
    final res = await ApiClient.post(
      ApiConstants.adminCancelarPlan(id),
      body,
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
        res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al cancelar el plan');
  }

  // ── Residente ─────────────────────────────────────────────────────

  static Future<PlanPagoModel> solicitar({
    required List<int> cobrosIds,
    required int numeroCuotas,
    String? observaciones,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.residentePlanesPago,
      {
        'cobrosIds': cobrosIds,
        'numeroCuotas': numeroCuotas,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
        res, PlanPagoModel.fromJson,
        successCodes: [201],
        fallbackMsg: 'Error al solicitar el plan');
  }

  static Future<List<PlanPagoModel>> misPlanes() async {
    final res = await ApiClient.get(
        ApiConstants.residentePlanesPago, requiresAuth: true);
    return BaseApiService.parseList(
        res, PlanPagoModel.fromJson, 'Error al obtener planes');
  }

  static Future<PlanPagoModel?> miPlanActivo() async {
    try {
      final res = await ApiClient.get(
          ApiConstants.residentePlanActivo, requiresAuth: true);
      if (res.statusCode == 404) return null;
      if (res.statusCode == 200) {
        return PlanPagoModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
