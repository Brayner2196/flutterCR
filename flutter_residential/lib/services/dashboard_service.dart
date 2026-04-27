import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard/dashboard_resumen.dart';
import '../models/dashboard/cartera_vencida.dart';
import '../models/dashboard/estado_unidades.dart';
import '../models/dashboard/pendientes_hoy.dart';
import '../models/dashboard/recaudo_mes.dart';
import '../models/dashboard/tendencia.dart';

class DashboardService {
  static Future<DashboardResumen> getResumen() async {
    final res = await ApiClient.get(ApiConstants.adminDashboard);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return DashboardResumen.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar el dashboard'));
  }

  static Future<PendientesHoy> getPendientes() async {
    final res = await ApiClient.get(ApiConstants.adminDashboardPendientes);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return PendientesHoy.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar pendientes'));
  }

  static Future<RecaudoMes> getRecaudo() async {
    final res = await ApiClient.get(ApiConstants.adminDashboardRecaudo);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return RecaudoMes.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar recaudo'));
  }

  static Future<CarteraVencida> getCartera() async {
    final res = await ApiClient.get(ApiConstants.adminDashboardCartera);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return CarteraVencida.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar cartera'));
  }

  static Future<Tendencia> getTendencia() async {
    final res = await ApiClient.get(ApiConstants.adminDashboardTendencia);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return Tendencia.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar tendencia'));
  }

  static Future<EstadoUnidades> getUnidades() async {
    final res = await ApiClient.get(ApiConstants.adminDashboardUnidades);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return EstadoUnidades.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cargar unidades'));
  }

  static String _msg(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return fallback;
  }
}
