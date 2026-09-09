import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/auditoria_model.dart';

/// Lectura del rastro financiero. Solo TENANT_ADMIN: el backend rechaza al
/// contador con 403, y es a propósito — no puede depurar su propio rastro.
class AuditoriaService {
  /// Página de la bandeja. Devuelve las filas y si quedan más por traer.
  static Future<({List<RegistroAuditoria> filas, bool hayMas})> buscar({
    FiltroAuditoria filtro = const FiltroAuditoria(),
    int page = 0,
    int size = 30,
  }) async {
    final params = {
      ...filtro.aQueryParams(),
      'page': '$page',
      'size': '$size',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final res = await ApiClient.get('${ApiConstants.adminAuditoria}?$query');
    if (res.statusCode != 200) {
      throw Exception('No se pudo cargar la auditoría');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final filas = (body['content'] as List<dynamic>? ?? [])
        .map((e) => RegistroAuditoria.fromJson(e as Map<String, dynamic>))
        .toList();

    return (filas: filas, hayMas: body['last'] != true);
  }

  /// Historia completa de un registro: "qué le pasó a este cobro".
  static Future<List<RegistroAuditoria>> rastroDe(String entidad, int entidadId) async {
    final res = await ApiClient.get(ApiConstants.auditoriaRastro(entidad, entidadId));
    if (res.statusCode != 200) {
      throw Exception('No se pudo cargar el historial del registro');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => RegistroAuditoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Valores válidos de los filtros. El backend los deriva de los enums, así
  /// que agregar una entidad nueva en Java la hace aparecer en el desplegable.
  static Future<({List<String> entidades, List<String> acciones})> filtros() async {
    final res = await ApiClient.get(ApiConstants.adminAuditoriaFiltros);
    if (res.statusCode != 200) {
      throw Exception('No se pudieron cargar los filtros');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      entidades: List<String>.from(body['entidades'] ?? const []),
      acciones: List<String>.from(body['acciones'] ?? const []),
    );
  }
}
