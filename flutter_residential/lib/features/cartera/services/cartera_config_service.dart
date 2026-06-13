import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/estado_cartera_config_model.dart';
import '../models/estado_cartera_vigente_model.dart';

class CarteraConfigService {
  /// Estado de cartera vigente de todas las propiedades, indexado por propiedadId.
  static Future<Map<int, EstadoCarteraVigente>> estadosVigentes() async {
    final response = await ApiClient.get(ApiConstants.carteraEstadosVigentes);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final lista = (body as List).map((e) => EstadoCarteraVigente.fromJson(e)).toList();
      return {for (final e in lista) e.propiedadId: e};
    }
    throw Exception(body is Map ? (body['message'] ?? 'Error al cargar estados') : 'Error al cargar estados');
  }

  static Future<List<EstadoCarteraConfig>> listar() async {
    final response = await ApiClient.get(ApiConstants.carteraEstados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List).map((e) => EstadoCarteraConfig.fromJson(e)).toList();
    }
    throw Exception(body is Map ? (body['message'] ?? 'Error al cargar estados') : 'Error al cargar estados');
  }

  static Future<EstadoCarteraConfig> crear(EstadoCarteraConfig estado) async {
    final response = await ApiClient.post(
      ApiConstants.carteraEstados,
      estado.toJson(),
      requiresAuth: true,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return EstadoCarteraConfig.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Error al crear el estado');
  }

  static Future<EstadoCarteraConfig> actualizar(int id, EstadoCarteraConfig estado) async {
    final response = await ApiClient.put('${ApiConstants.carteraEstados}/$id', estado.toJson());
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return EstadoCarteraConfig.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Error al actualizar el estado');
  }

  static Future<void> eliminar(int id) async {
    final response = await ApiClient.delete('${ApiConstants.carteraEstados}/$id');
    if (response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al eliminar el estado');
    }
  }

  static Future<List<EstadoCarteraConfig>> sembrarDefaults() async {
    final response = await ApiClient.post(ApiConstants.carteraSeed, {}, requiresAuth: true);
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return (body as List).map((e) => EstadoCarteraConfig.fromJson(e)).toList();
    }
    throw Exception(body is Map ? (body['message'] ?? 'Error al sembrar estados') : 'Error al sembrar estados');
  }
}
