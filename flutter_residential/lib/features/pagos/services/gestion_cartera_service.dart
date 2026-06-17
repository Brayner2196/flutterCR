import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/aviso_cobranza_resultado.dart';

/// Servicio de gestión de cobranza: envío de avisos a morosos.
/// Lógica de red aislada y reutilizable (sin estado de UI).
class GestionCarteraService {
  GestionCarteraService._();

  /// Notifica a los residentes de una propiedad. Si [estadoCarteraId] es null,
  /// el backend usa la fase de cartera vigente de la propiedad.
  static Future<AvisoCobranzaResultado> notificarPropiedad(
    int propiedadId, {
    int? estadoCarteraId,
    String? mensaje,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.carteraNotificar(propiedadId),
      {
        if (estadoCarteraId != null) 'estadoCarteraId': estadoCarteraId,
        if (mensaje != null && mensaje.trim().isNotEmpty) 'mensaje': mensaje.trim(),
      },
      requiresAuth: true,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return AvisoCobranzaResultado.fromJson(body);
    }
    throw Exception(body is Map
        ? (body['message'] ?? 'Error al enviar el aviso')
        : 'Error al enviar el aviso');
  }

  /// Notifica a todas las propiedades cuya fase vigente sea [estadoCarteraId].
  static Future<List<AvisoCobranzaResultado>> notificarMasivoPorEstado(
    int estadoCarteraId, {
    String? mensaje,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.carteraNotificarMasivo,
      {
        'estadoCarteraId': estadoCarteraId,
        if (mensaje != null && mensaje.trim().isNotEmpty) 'mensaje': mensaje.trim(),
      },
      requiresAuth: true,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((e) => AvisoCobranzaResultado.fromJson(e))
          .toList();
    }
    throw Exception(body is Map
        ? (body['message'] ?? 'Error al enviar los avisos')
        : 'Error al enviar los avisos');
  }
}
