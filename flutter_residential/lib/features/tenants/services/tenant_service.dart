import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/operacion_destructiva_response.dart';
import '../models/tenant_response.dart';

class TenantService {
  static Future<List<TenantResponse>> listarTodos() async {
    final response = await ApiClient.get(ApiConstants.tenants);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (body as List).map((e) => TenantResponse.fromJson(e)).toList();
    }

    throw Exception(body['message'] ?? 'Error al cargar tenants');
  }

  static Future<TenantResponse> obtenerPorId(int id) async {
    final response = await ApiClient.get('${ApiConstants.tenants}/$id');
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return TenantResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al obtener tenant');
  }

  static Future<TenantResponse> crear(Map<String, dynamic> datos) async {
    final response = await ApiClient.post(
      ApiConstants.tenants,
      datos,
      requiresAuth: true,
    );
    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return TenantResponse.fromJson({
        'id': body['tenantId'],
        'schemaName': body['schemaName'],
        'nombre': body['nombre'],
        'codigo': body['codigo'],
        'activo': true,
        'direccion': datos['direccion'],
      });
    }

    throw Exception(body['message'] ?? 'Error al crear tenant');
  }

  static Future<TenantResponse> actualizar( int id, Map<String, dynamic> datos ) async {
    final response = await ApiClient.put('${ApiConstants.tenants}/$id', datos);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return TenantResponse.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Error al actualizar tenant');
  }

  static Future<void> desactivar(int id) async {
    final response = await ApiClient.delete('${ApiConstants.tenants}/$id');

    if (response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al desactivar tenant');
    }
  }

  static Future<void> activar(int id) async {
    final response = await ApiClient.patch('${ApiConstants.tenants}/$id/activar');

    if (response.statusCode != 204) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al activar tenant');
    }
  }

  // ─── Operaciones destructivas ────────────────────────────────────────────

  /// Vacía TODOS los datos del conjunto conservando sus tablas y su
  /// administrador. [codigoConfirmacion] debe ser el código exacto del
  /// conjunto; si no coincide, el backend responde 400.
  static Future<OperacionDestructivaResponse> vaciarDatos({
    required int id,
    required String codigoConfirmacion,
  }) async {
    return _operacionDestructiva(
      ApiConstants.tenantVaciarDatos(id),
      codigoConfirmacion,
      'Error al vaciar los datos del conjunto',
    );
  }

  /// Elimina el conjunto POR COMPLETO: schema, identidades, tokens y
  /// pasarelas. Irreversible.
  static Future<OperacionDestructivaResponse> eliminarDefinitivo({
    required int id,
    required String codigoConfirmacion,
  }) async {
    return _operacionDestructiva(
      ApiConstants.tenantEliminarDefinitivo(id),
      codigoConfirmacion,
      'Error al eliminar el conjunto',
    );
  }

  /// Las dos operaciones destructivas comparten contrato: mismo body de
  /// confirmación y misma respuesta. Se factoriza para no duplicar el parseo
  /// ni el manejo de error.
  static Future<OperacionDestructivaResponse> _operacionDestructiva(
    String ruta,
    String codigoConfirmacion,
    String mensajeError,
  ) async {
    final response = await ApiClient.post(
      ruta,
      {'codigoConfirmacion': codigoConfirmacion},
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      return OperacionDestructivaResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    // El body puede no ser JSON (500/HTML): parseo defensivo.
    String msg = '$mensajeError (HTTP ${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) msg = body['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  /// Re-provisiona el esquema de todos los tenants (crea tablas faltantes).
  /// Devuelve los tenants procesados y la lista de errores por schema (si los hubo).
  static Future<({int procesados, List<String> errores})> reprovisionar() async {
    final response = await ApiClient.post(
      ApiConstants.tenantsReprovisionar,
      {},
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        procesados: (body['tenantsProcesados'] ?? 0) as int,
        errores: ((body['errores'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
    }

    // Errores no-200: el body puede no ser JSON (500/HTML). Parse defensivo.
    String msg = 'Error al reprovisionar tenants (HTTP ${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) msg = body['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

}
