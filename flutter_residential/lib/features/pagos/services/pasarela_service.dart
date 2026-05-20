import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/pasarela_disponible_model.dart';

/// Servicio genérico de pasarelas de pago.
/// Reemplaza gradualmente a MercadoPagoService para los flujos nuevos.
class PasarelaService {
  /// Obtiene las pasarelas activas del tenant del residente autenticado.
  static Future<List<PasarelaDisponibleModel>> obtenerDisponibles() async {
    final res = await ApiClient.get(
      ApiConstants.pasarelasDisponibles,
      requiresAuth: true,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => PasarelaDisponibleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener pasarelas disponibles');
  }

  /// Crea un checkout en la pasarela elegida y devuelve la URL + tipo.
  /// [monto] opcional para abonos parciales.
  static Future<CheckoutResponseModel> crearCheckout(
    int cobroId,
    TipoPasarela pasarela, {
    double? monto,
  }) async {
    final body = <String, dynamic>{
      'pasarela': pasarela.backendValue,
      if (monto != null) 'monto': monto,
    };

    final res = await ApiClient.post(
      ApiConstants.pagoCheckout(cobroId),
      body,
      requiresAuth: true,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return CheckoutResponseModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    final errorBody = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(errorBody['message'] ?? 'Error al iniciar el pago');
  }

  /// Confirma un pago de MercadoPago desde la app (back_url).
  static Future<void> confirmarPagoMP(String paymentId) async {
    await ApiClient.post(
      ApiConstants.mpConfirmarPago(paymentId),
      {},
      requiresAuth: false,
    );
  }
}
