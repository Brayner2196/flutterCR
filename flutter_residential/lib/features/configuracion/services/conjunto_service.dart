import 'dart:convert';
import 'package:flutter_residential/core/constants/api_constants.dart';
import 'package:flutter_residential/core/network/api_client.dart';
import '../models/conjunto_model.dart';

class ConjuntoService {
  static Future<ConjuntoModel> obtener() async {
    final res = await ApiClient.get(ApiConstants.adminMiConjunto);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return ConjuntoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al obtener datos del conjunto');
  }

  static Future<ConjuntoModel> actualizar({
    required String nombre,
    String? direccion,
  }) async {
    final res = await ApiClient.patch(
      ApiConstants.adminMiConjunto,
      {'nombre': nombre, if (direccion != null) 'direccion': direccion},
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return ConjuntoModel.fromJson(body);
    throw Exception(body['message'] ?? 'Error al guardar cambios');
  }
}
