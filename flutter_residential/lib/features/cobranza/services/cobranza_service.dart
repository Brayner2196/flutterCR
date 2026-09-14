import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../../pagos/models/aviso_cobranza_resultado.dart';
import '../models/cobro_cobranza_model.dart';

/// Red del módulo de cobranza. Sin estado de UI, reutilizable desde cualquier
/// pantalla (pestaña de cobranza, dashboard, futuros reportes).
class CobranzaService {
  CobranzaService._();

  /// Cartera morosa. El backend ya excluye exonerados y pagados.
  ///
  /// [meses] acota la ventana histórica; 0 trae toda la cartera (usarlo solo
  /// bajo petición explícita: en un conjunto con cartera migrada son miles de
  /// filas).
  static Future<List<CobroCobranzaModel>> listar({
    int? periodoId,
    int meses = 12,
    bool soloEspeciales = false,
  }) async {
    final params = <String>['meses=$meses'];
    if (periodoId != null) params.add('periodoId=$periodoId');
    if (soloEspeciales) params.add('soloEspeciales=true');
    final res = await ApiClient.get('${ApiConstants.adminCobranza}?${params.join('&')}');
    return BaseApiService.parseList(
      res,
      CobroCobranzaModel.fromJson,
      'Error al cargar la cartera',
    );
  }

  /// Aviso a varias propiedades en una sola petición.
  ///
  /// Recibe ids de PROPIEDAD, no de cobro: al residente le llega un aviso por
  /// propiedad aunque tenga cinco cuotas vencidas. Si [estadoCarteraId] es null
  /// el backend cita la fase vigente de cada una, que es lo correcto cuando la
  /// selección mezcla propiedades en distintos niveles de mora.
  static Future<List<AvisoCobranzaResultado>> notificarLote(
    List<int> propiedadIds, {
    int? estadoCarteraId,
    String? mensaje,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.cobranzaNotificarLote,
      {
        'propiedadIds': propiedadIds,
        'estadoCarteraId': ?estadoCarteraId,
        if (mensaje != null && mensaje.trim().isNotEmpty) 'mensaje': mensaje.trim(),
      },
      requiresAuth: true,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List).map((e) => AvisoCobranzaResultado.fromJson(e)).toList();
    }
    throw Exception(body is Map
        ? (body['message'] ?? 'Error al enviar los avisos')
        : 'Error al enviar los avisos');
  }
}
