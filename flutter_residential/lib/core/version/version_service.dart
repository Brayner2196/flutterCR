import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'app_version.dart';
import 'estado_version.dart';

/// Consulta al backend en qué estado está esta versión.
///
/// No usa `ApiClient` a propósito, por tres motivos:
///  - corre antes del login, cuando no hay token ni conjunto que mandar;
///  - un 401 aquí no debe disparar el `sessionExpiredStream` ni cerrar sesión;
///  - necesita un tiempo de espera corto y propio. Los 15 segundos del
///    `ApiClient` son razonables para cargar la cartera, no para una
///    comprobación opcional que corre en el splash: nadie debe mirar un
///    indicador de carga 15 segundos por algo que puede omitirse.
class VersionService {
  VersionService._();

  /// Corto a propósito. Si el backend no contesta en 3 segundos, se entra igual.
  static const Duration _timeout = Duration(seconds: 3);

  /// Identificador que entiende el backend (`PlataformaApp`).
  static String get plataforma {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return 'WEB'; // escritorio: se comporta como la web
    }
  }

  /// Nunca lanza. Ante cualquier problema devuelve [InfoVersion.desconocido],
  /// que el resto del sistema trata como "deja pasar".
  static Future<InfoVersion> consultar() async {
    // Build sin defines (un `flutter run` a secas): no hay nada que comparar.
    if (!AppVersion.conocida) return InfoVersion.alDia;

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.version}'
        '?plataforma=$plataforma&build=${AppVersion.build}',
      );

      final res = await http.get(uri).timeout(_timeout);

      if (res.statusCode != 200) return InfoVersion.desconocido;

      final cuerpo = res.body.trim();
      if (cuerpo.isEmpty) return InfoVersion.desconocido;

      return InfoVersion.desdeJson(jsonDecode(cuerpo) as Map<String, dynamic>);
    } catch (_) {
      // Sin red, DNS caído, JSON corrupto, tiempo agotado: da igual cuál.
      // El usuario entra.
      return InfoVersion.desconocido;
    }
  }
}
