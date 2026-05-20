import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/cobro_model.dart';
import '../models/estado_cuenta_model.dart';
import '../models/movimiento_cobro_model.dart';
import '../models/periodo_cobro_model.dart';

class CobroService {
  // ─── Admin ────────────────────────────────────────────

  static Future<PeriodoCobroModel> abrirPeriodo(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminPeriodos, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, PeriodoCobroModel.fromJson,
        successCodes: [201], fallbackMsg: 'Error al abrir período');
  }

  static Future<List<PeriodoCobroModel>> listarPeriodos() async {
    final res = await ApiClient.get(ApiConstants.adminPeriodos, requiresAuth: true);
    return BaseApiService.parseList(res, PeriodoCobroModel.fromJson, 'Error al listar períodos');
  }

  static Future<PeriodoCobroModel> cerrarPeriodo(int id) async {
    final res = await ApiClient.put(ApiConstants.cerrarPeriodo(id), {});
    return BaseApiService.parseSingle(res, PeriodoCobroModel.fromJson,
        fallbackMsg: 'Error al cerrar período');
  }

  static Future<List<CobroModel>> generarCobros(int anio, int mes) async {
    final res = await ApiClient.post(ApiConstants.generarCobros(anio, mes), {}, requiresAuth: true);
    return BaseApiService.parseList(res, CobroModel.fromJson, 'Error al generar cobros');
  }

  static Future<List<CobroModel>> listarCobrosAdmin({int? periodoId, String? estado}) async {
    String url = ApiConstants.adminCobros;
    final params = <String>[];
    if (periodoId != null) params.add('periodoId=$periodoId');
    if (estado != null) params.add('estado=$estado');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, CobroModel.fromJson, 'Error al listar cobros');
  }

  static Future<CobroModel> crearCobroEspecial(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminCobrosEspeciales, data, requiresAuth: true);
    return BaseApiService.parseSingle(res, CobroModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear cobro especial');
  }

  static Future<CobroModel> exonerar(int id, String nota) async {
    final res = await ApiClient.put(ApiConstants.exonerarCobro(id), {'nota': nota});
    return BaseApiService.parseSingle(res, CobroModel.fromJson,
        fallbackMsg: 'Error al exonerar cobro');
  }

  static Future<List<CobroModel>> listarCobrosDeUsuario(int usuarioId) async {
    final res = await ApiClient.get(ApiConstants.adminCobrosPorUsuario(usuarioId));
    return BaseApiService.parseList(
        res, CobroModel.fromJson, 'Error al obtener cobros del usuario');
  }

  static Future<EstadoCuentaModel> getEstadoCuentaUsuario(int usuarioId) async {
    final res = await ApiClient.get(ApiConstants.adminEstadoCuentaUsuario(usuarioId));
    return BaseApiService.parseSingle(res, EstadoCuentaModel.fromJson,
        fallbackMsg: 'Error al obtener estado de cuenta');
  }

  // ─── Residente ─────────────────────────────────────

  static Future<EstadoCuentaModel> getEstadoCuenta() async {
    final res = await ApiClient.get(ApiConstants.estadoCuenta);
    return BaseApiService.parseSingle(res, EstadoCuentaModel.fromJson,
        fallbackMsg: 'Error al obtener estado de cuenta');
  }

  static Future<List<CobroModel>> getMisCobros({String? estado}) async {
    String url = ApiConstants.misCobros;
    if (estado != null) url += '?estado=$estado';
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(res, CobroModel.fromJson, 'Error al obtener cobros');
  }

  static Future<CobroModel> getCobro(int id) async {
    final res = await ApiClient.get(ApiConstants.miCobro(id));
    return BaseApiService.parseSingle(res, CobroModel.fromJson,
        fallbackMsg: 'Error al obtener cobro');
  }

  static Future<List<MovimientoCobroModel>> getMovimientosCobro(int cobroId) async {
    final res = await ApiClient.get(ApiConstants.movimientosCobro(cobroId));
    return BaseApiService.parseList(
        res, MovimientoCobroModel.fromJson, 'Error al obtener movimientos del cobro');
  }

  static Future<List<CobroModel>> getHistorial() async {
    final res = await ApiClient.get(ApiConstants.historialCobros);
    return BaseApiService.parseList(res, CobroModel.fromJson, 'Error al obtener historial');
  }
}
