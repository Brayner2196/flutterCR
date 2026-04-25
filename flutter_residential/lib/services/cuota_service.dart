import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/configuracion_cuota_model.dart';

class CuotaService {
  static Future<List<ConfiguracionCuotaModel>> listar() async {
    final res = await ApiClient.get(ApiConstants.adminCuotas);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List).map((e) => ConfiguracionCuotaModel.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar cuotas');
  }

  static Future<ConfiguracionCuotaModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminCuotas, data);
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) return ConfiguracionCuotaModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al crear cuota');
  }

  static Future<void> desactivar(int id) async {
    final res = await ApiClient.put(ApiConstants.desactivarCuota(id), {});
    if (res.statusCode != 204) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Error al desactivar cuota');
    }
  }
}
