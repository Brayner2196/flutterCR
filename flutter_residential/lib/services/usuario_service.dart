import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/usuario_response.dart';

class UsuarioService {
  static Future<List<UsuarioResponse>> listarTodos() async {
    final response = await ApiClient.get(ApiConstants.usuarios);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (body as List).map((e) => UsuarioResponse.fromJson(e)).toList();
    }

    throw Exception(body['message'] ?? 'Error al cargar usuarios');
  }

  static Future<List<UsuarioResponse>> listarPendientes() async {
    final response = await ApiClient.get(ApiConstants.usuariosPendientes);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (body as List).map((e) => UsuarioResponse.fromJson(e)).toList();
    }

    throw Exception(body['message'] ?? 'Error al cargar pendientes');
  }

  static Future<UsuarioResponse> aprobar(int id) async {
    final response = await ApiClient.put(
      '${ApiConstants.usuarios}/$id/aprobar',
      {},
    );
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al aprobar usuario');
  }

  static Future<UsuarioResponse> rechazar(int id) async {
    final response = await ApiClient.put(
      '${ApiConstants.usuarios}/$id/rechazar',
      {},
    );
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al rechazar usuario');
  }

  static Future<UsuarioResponse> buscarPorId(int id) async {
    final response = await ApiClient.get('${ApiConstants.usuarios}/$id');
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UsuarioResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al buscar usuario');
  }

  static Future<UsuarioResponse> actualizar(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('${ApiConstants.usuarios}/$id', data);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return UsuarioResponse.fromJson(body);
    throw Exception(body['message'] ?? 'Error al actualizar usuario');
  }
}
