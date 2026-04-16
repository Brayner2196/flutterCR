import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/usuario_response.dart';

class UsuarioService {
  static Future<List<UsuarioResponse>> listarTodos() async {
    final response = await ApiClient.get(ApiConstants.usuarios);
    return _parseList(response, 'Error al cargar usuarios');
  }

  static Future<UsuarioResponse> crear(Map<String, dynamic> data) async {
    final response = await ApiClient.post(
      ApiConstants.usuarios,
      data,
      requiresAuth: true,
    );
    return _parseSingle(response, [200, 201], 'Error al crear usuario');
  }

  static Future<UsuarioResponse> aprobar(int id) async {
    final response = await ApiClient.put(
      '${ApiConstants.usuarios}/$id/aprobar',
      {},
    );
    return _parseSingle(response, [200], 'Error al aprobar usuario');
  }

  static Future<UsuarioResponse> rechazar(int id) async {
    final response = await ApiClient.put(
      '${ApiConstants.usuarios}/$id/rechazar',
      {},
    );
    return _parseSingle(response, [200], 'Error al rechazar usuario');
  }

  static Future<UsuarioResponse> buscarPorId(int id) async {
    final response = await ApiClient.get('${ApiConstants.usuarios}/$id');
    return _parseSingle(response, [200], 'Error al buscar usuario');
  }

  static Future<UsuarioResponse> actualizar(
      int id, Map<String, dynamic> data) async {
    final response =
        await ApiClient.put('${ApiConstants.usuarios}/$id', data);
    return _parseSingle(response, [200], 'Error al actualizar usuario');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<UsuarioResponse> _parseList(
      dynamic response, String fallbackMsg) {
    final body = _decodeBody(response, fallbackMsg);
    if (response.statusCode == 200) {
      return (body as List).map((e) => UsuarioResponse.fromJson(e)).toList();
    }
    throw Exception(_extractMessage(body, fallbackMsg));
  }

  static UsuarioResponse _parseSingle(
      dynamic response, List<int> successCodes, String fallbackMsg) {
    final body = _decodeBody(response, fallbackMsg);
    if (successCodes.contains(response.statusCode)) {
      return UsuarioResponse.fromJson(body);
    }
    throw Exception(_extractMessage(body, fallbackMsg));
  }

  static dynamic _decodeBody(dynamic response, String fallbackMsg) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('$fallbackMsg: respuesta inesperada del servidor.');
    }
  }

  static String _extractMessage(dynamic body, String fallback) {
    if (body is Map) {
      return (body['message'] as String?) ??
          (body['error'] as String?) ??
          fallback;
    }
    return fallback;
  }
}
