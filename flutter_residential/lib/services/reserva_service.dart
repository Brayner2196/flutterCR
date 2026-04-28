import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/reserva_model.dart';

class ReservaService {
  // ─── Admin ─────────────────────────────────────

  static Future<List<ReservaModel>> listarAdmin({String? estado}) async {
    final url = estado == null
        ? ApiConstants.adminReservas
        : '${ApiConstants.adminReservas}?estado=$estado';
    final res = await ApiClient.get(url);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ReservaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al listar reservas'));
  }

  static Future<ReservaModel> aprobar(int id, {String? motivo}) async {
    final res = await ApiClient.put(
        ApiConstants.aprobarReserva(id), {'motivo': motivo});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ReservaModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al aprobar reserva'));
  }

  static Future<ReservaModel> rechazar(int id, String motivo) async {
    final res = await ApiClient.put(
        ApiConstants.rechazarReserva(id), {'motivo': motivo});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ReservaModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al rechazar reserva'));
  }

  static Future<List<ZonaComunModel>> listarZonasAdmin() async {
    final res = await ApiClient.get(ApiConstants.adminZonasComunes);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ZonaComunModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al listar zonas'));
  }

  // ─── Residente ────────────────────────────────

  static Future<List<ZonaComunModel>> zonasActivas() async {
    final res = await ApiClient.get(ApiConstants.residenteZonasComunes);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ZonaComunModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al listar zonas'));
  }

  static Future<ReservaModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(
        ApiConstants.residenteReservas, data, requiresAuth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return ReservaModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al crear reserva'));
  }

  static Future<List<ReservaModel>> misReservas() async {
    final res = await ApiClient.get(ApiConstants.misReservas);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ReservaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(body, 'Error al obtener tus reservas'));
  }

  static Future<ReservaModel> cancelar(int id) async {
    final res = await ApiClient.put(ApiConstants.cancelarReserva(id), {});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ReservaModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_msg(body, 'Error al cancelar reserva'));
  }

  static String _msg(dynamic body, String fallback) {
    if (body is Map && body['message'] != null) return body['message'].toString();
    return fallback;
  }
}
