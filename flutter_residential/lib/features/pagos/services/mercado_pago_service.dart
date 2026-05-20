import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MercadoPagoService {
  /// Solicita al backend la URL de checkout de MercadoPago para el cobro dado.
  /// El backend crea la preferencia y devuelve el sandbox_init_point.
  ///
  /// [monto] opcional: si se envía, el backend crea una preferencia por ese
  /// valor (abono / valor diferente). Si es mayor al pendiente, el exceso
  /// se registra como saldo a favor al confirmar el pago.
  static Future<String> obtenerCheckoutUrl(int cobroId, {double? monto}) async {
    final payload = monto != null ? {'monto': monto} : <String, dynamic>{};
    final res = await ApiClient.post(
      ApiConstants.mpPreferencia(cobroId),
      payload,
      requiresAuth: true,
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final url = body['checkoutUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No se recibió URL de checkout');
      }
      return url;
    }
    throw Exception(body['message'] ?? 'Error al iniciar pago con MercadoPago');
  }

  /// Notifica al backend que el pago fue aprobado/pendiente por MP.
  /// Se llama desde el WebView al interceptar la back_url de éxito/pendiente.
  /// Es idempotente: si el webhook ya lo procesó, el backend lo ignora.
  static Future<void> confirmarPago(String paymentId) async {
    await ApiClient.post(
      ApiConstants.mpConfirmarPago(paymentId),
      {},
      requiresAuth: false,
    );
  }
}
