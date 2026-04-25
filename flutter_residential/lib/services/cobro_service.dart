import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/cobro_model.dart';
import '../models/estado_cuenta_model.dart';
import '../models/periodo_cobro_model.dart';

class CobroService {
  // ─── Admin ────────────────────────────────────────────

  static Future<PeriodoCobroModel> abrirPeriodo(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminPeriodos, data);
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) return PeriodoCobroModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al abrir período');
  }

  static Future<List<PeriodoCobroModel>> listarPeriodos() async {
    final res = await ApiClient.get(ApiConstants.adminPeriodos);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => PeriodoCobroModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar períodos');
  }

  static Future<PeriodoCobroModel> cerrarPeriodo(int id) async {
    final res = await ApiClient.put(ApiConstants.cerrarPeriodo(id), {});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return PeriodoCobroModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al cerrar período');
  }

  static Future<List<CobroModel>> generarCobros(int anio, int mes) async {
    final res = await ApiClient.post(ApiConstants.generarCobros(anio, mes), {});
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return (body as List).map((e) => CobroModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al generar cobros');
  }

  static Future<List<CobroModel>> listarCobrosAdmin(
      {int? periodoId, String? estado}) async {
    String url = ApiConstants.adminCobros;
    final params = <String>[];
    if (periodoId != null) params.add('periodoId=$periodoId');
    if (estado != null) params.add('estado=$estado');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => CobroModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar cobros');
  }

  static Future<CobroModel> exonerar(int id, String nota) async {
    final res = await ApiClient.put(ApiConstants.exonerarCobro(id), {'nota': nota});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return CobroModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al exonerar cobro');
  }

  // ─── Residente ─────────────────────────────────────

  static Future<EstadoCuentaModel> getEstadoCuenta() async {
    final res = await ApiClient.get(ApiConstants.estadoCuenta);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return EstadoCuentaModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al obtener estado de cuenta');
  }

  static Future<List<CobroModel>> getMisCobros({String? estado}) async {
    String url = ApiConstants.misCobros;
    if (estado != null) url += '?estado=$estado';
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => CobroModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener cobros');
  }

  static Future<List<CobroModel>> getHistorial() async {
    final res = await ApiClient.get(ApiConstants.historialCobros);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => CobroModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al obtener historial');
  }
}
