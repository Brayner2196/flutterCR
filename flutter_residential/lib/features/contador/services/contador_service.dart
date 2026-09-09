import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/contador_model.dart';
import '../models/permiso_contable_model.dart';

/// Llamadas del rol contable. Dos audiencias en un solo sitio:
///   · [misPermisos]  — lo consulta el propio usuario (contador o admin)
///   · el resto       — administracion de OTROS contadores, solo TENANT_ADMIN
class ContadorService {
  /// Alcance del usuario autenticado. Devuelve el par (esAdministrador, permisos).
  ///
  /// El admin recibe el catalogo completo con `administrador = true`, que es lo
  /// que el backend responde de verdad para el: asi la app y el servidor dicen
  /// lo mismo y no hay que ramificar por rol en cada pantalla.
  static Future<({bool administrador, Set<String> permisos})> misPermisos() async {
    final res = await ApiClient.get(ApiConstants.contableMisPermisos);
    if (res.statusCode != 200) {
      throw Exception('No se pudieron cargar los permisos contables');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      administrador: body['administrador'] == true,
      permisos: Set<String>.from(body['permisos'] ?? const []),
    );
  }

  /// Catalogo de permisos disponibles, sin marcar. Util para pintar la pantalla
  /// antes de elegir un contador.
  static Future<List<PermisoContable>> catalogo() async {
    final res = await ApiClient.get(ApiConstants.adminContadoresPermisos);
    if (res.statusCode != 200) {
      throw Exception('No se pudo cargar el catalogo de permisos');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => PermisoContable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Contador>> listar() async {
    final res = await ApiClient.get(ApiConstants.adminContadores);
    if (res.statusCode != 200) {
      throw Exception('No se pudieron cargar los contadores');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => Contador.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Contador> detalle(int usuarioId) async {
    final res = await ApiClient.get(ApiConstants.contadorDetalle(usuarioId));
    if (res.statusCode != 200) {
      throw Exception('No se pudo cargar el contador');
    }
    return Contador.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Reemplaza el alcance completo. Se manda el conjunto final, no un delta:
  /// el backend calcula que otorgar y que revocar, y la auditoria queda con un
  /// solo antes/despues legible en vez de N filas sueltas.
  static Future<Contador> guardarPermisos(
      int usuarioId, List<String> permisos) async {
    final res = await ApiClient.put(
      ApiConstants.contadorPermisos(usuarioId),
      {'permisos': permisos},
    );
    if (res.statusCode != 200) {
      throw Exception(_mensajeError(res.body) ?? 'No se pudieron guardar los permisos');
    }
    return Contador.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Deja al contador sin ningun permiso, sin borrar el usuario.
  static Future<Contador> revocarTodo(int usuarioId) async {
    final res = await ApiClient.delete(ApiConstants.contadorPermisos(usuarioId));
    if (res.statusCode != 200) {
      throw Exception('No se pudo revocar el alcance');
    }
    return Contador.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// El backend contesta 409 con un mensaje util cuando el usuario no tiene rol
  /// CONTADOR. Vale la pena mostrarlo tal cual en vez de un error generico.
  static String? _mensajeError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['message'] as String?;
      }
    } catch (_) {
      // cuerpo no-JSON: se usa el mensaje por defecto
    }
    return null;
  }
}
