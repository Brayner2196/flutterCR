import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/modulo_estado.dart';

/// Acceso HTTP a la configuración de módulos.
///
/// Dos audiencias distintas, por eso dos grupos de métodos:
/// - [misModulos]: cualquier usuario del conjunto, para saber qué pintar.
/// - [listarDeTenant] / [toggle]: solo SUPER_ADMIN, para configurar conjuntos.
class ModuloService {
  // ─── Usuario del conjunto ────────────────────────────────────────────────

  /// Códigos de los módulos habilitados en el conjunto de la sesión actual.
  static Future<Set<String>> misModulos() async {
    final res = await ApiClient.get(ApiConstants.misModulos);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return Set<String>.from(body['modulos'] ?? const []);
    }
    throw Exception('Error al cargar los módulos del conjunto');
  }

  // ─── SUPER_ADMIN ─────────────────────────────────────────────────────────

  /// Catálogo completo de módulos de un conjunto, con su estado.
  static Future<List<ModuloEstado>> listarDeTenant(int tenantId) async {
    final res = await ApiClient.get(ApiConstants.tenantModulos(tenantId));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ModuloEstado.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Error al cargar los módulos');
  }

  /// Enciende o apaga un módulo. El backend responde con el catálogo ya
  /// actualizado (apagar un padre arrastra a sus dependientes), así que no
  /// hace falta un segundo GET.
  static Future<List<ModuloEstado>> toggle({
    required int tenantId,
    required String codigo,
    required bool activo,
  }) async {
    final res = await ApiClient.patch(
      ApiConstants.tenantModulos(tenantId),
      {'modulo': codigo, 'activo': activo},
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return (body as List)
          .map((e) => ModuloEstado.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Error al actualizar el módulo');
  }
}
