import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/configuracion_plan_pago_model.dart';
import '../models/elegibilidad_acuerdo_model.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';

/// Acceso HTTP del módulo de acuerdos de pago.
class PlanPagoService {
  // ── Configuración ─────────────────────────────────────────────────

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
        res, PlanPagoModel.fromJson, 'Error al listar acuerdos');
  }

  static Future<PlanPagoModel> detalle(int id) async {
    final res = await ApiClient.get(
        ApiConstants.adminPlanPago(id), requiresAuth: true);
    return BaseApiService.parseSingle(res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al obtener el acuerdo');
  }

  static Future<PlanPagoModel> decidir(int id, bool aprobar,
      {String? motivoRechazo, String? nota}) async {
    final res = await ApiClient.post(
      ApiConstants.adminDecidirPlan(id),
      {
        'aprobar': aprobar,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
        if (nota != null) 'notaAdmin': nota,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al procesar la decisión');
  }

  static Future<PlanPagoModel> cancelarPlan(int id, {String? nota}) async {
    final body = nota != null ? {'nota': nota} : <String, dynamic>{};
    final res = await ApiClient.post(
        ApiConstants.adminCancelarPlan(id), body, requiresAuth: true);
    return BaseApiService.parseSingle(res, PlanPagoModel.fromJson,
        fallbackMsg: 'Error al cancelar el acuerdo');
  }

  // ── Residente ─────────────────────────────────────────────────────

  /// ¿La propiedad cumple las condiciones? Devuelve también los motivos.
  static Future<ElegibilidadAcuerdoModel> elegibilidad({int? propiedadId}) async {
    final url = propiedadId != null
        ? '${ApiConstants.residenteAcuerdoElegibilidad}?propiedadId=$propiedadId'
        : ApiConstants.residenteAcuerdoElegibilidad;
    final res = await ApiClient.get(url, requiresAuth: true);
    return BaseApiService.parseSingle(res, ElegibilidadAcuerdoModel.fromJson,
        fallbackMsg: 'Error al verificar elegibilidad');
  }

  /// Previsualización: abono inicial, saldo diferido y cuotas.
  static Future<SimulacionAcuerdoModel> simular({
    int? propiedadId,
    required int numeroCuotas,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.residenteSimularAcuerdo,
      {
        if (propiedadId != null) 'propiedadId': propiedadId,
        'numeroCuotas': numeroCuotas,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, SimulacionAcuerdoModel.fromJson,
        fallbackMsg: 'Error al simular el acuerdo');
  }

  static Future<PlanPagoModel> solicitar({
    int? propiedadId,
    required int numeroCuotas,
    String? observaciones,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.residentePlanesPago,
      {
        if (propiedadId != null) 'propiedadId': propiedadId,
        'numeroCuotas': numeroCuotas,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(res, PlanPagoModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al solicitar el acuerdo');
  }

  static Future<List<PlanPagoModel>> misPlanes() async {
    final res = await ApiClient.get(
        ApiConstants.residentePlanesPago, requiresAuth: true);
    return BaseApiService.parseList(
        res, PlanPagoModel.fromJson, 'Error al obtener acuerdos');
  }

  /// Acuerdo vigente. 404 (sin acuerdo) es un caso normal, no un error.
  static Future<PlanPagoModel?> miPlanActivo() async {
    try {
      final res = await ApiClient.get(
          ApiConstants.residentePlanActivo, requiresAuth: true);
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
