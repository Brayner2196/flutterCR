import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/miembro_consejo_model.dart';

class AdminConsejoService {
  /// Lista los miembros activos del consejo.
  static Future<List<MiembroConsejoModel>> listarActivos() async {
    final res = await ApiClient.get(ApiConstants.adminConsejo);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => MiembroConsejoModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al cargar el consejo (${res.statusCode})');
  }

  /// Designa a un usuario como miembro del consejo.
  static Future<MiembroConsejoModel> designar({
    required int usuarioId,
    required String cargo,
    required String fechaInicio,
    String? fechaFin,
  }) async {
    final body = <String, dynamic>{
      'usuarioId': usuarioId,
      'cargo': cargo,
      'fechaInicio': fechaInicio,
      if (fechaFin != null) 'fechaFin': fechaFin,
    };
    final res = await ApiClient.post(ApiConstants.adminConsejo, body, requiresAuth: true);
    if (res.statusCode == 201) {
      return MiembroConsejoModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    final msg = _extractError(res.body);
    throw Exception(msg);
  }

  /// Revoca la membresía de un consejero (activo = false).
  static Future<void> revocar(int id) async {
    final res = await ApiClient.delete(ApiConstants.adminConsejoId(id));
    if (res.statusCode != 204) {
      final msg = _extractError(res.body);
      throw Exception(msg);
    }
  }

  /// Extrae el mensaje de error del body si es JSON, si no devuelve genérico.
  static String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? 'Error desconocido';
    } catch (_) {
      return 'Error al procesar la solicitud';
    }
  }
}
