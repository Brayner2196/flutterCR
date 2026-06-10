import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';
import '../services/pasarela_service.dart';
import 'pasarela_pago.dart';

/// Implementación de [PasarelaPago] para Mercado Pago Checkout Pro.
///
/// Equivalente a MercadoPagoServiceImpl en Spring Boot.
class MercadoPagoPasarela implements PasarelaPago {
  const MercadoPagoPasarela();

  @override
  TipoPasarela get tipo => TipoPasarela.mercadoPago;

  @override
  String get nombre => 'Mercado Pago';

  @override
  Color get color => const Color(0xFF009EE3);

  @override
  IconData get icono => Icons.payment;

  @override
  String get descripcion => 'Tarjetas, PSE, efectivo';

  @override
  Future<CheckoutResponseModel> crearCheckout(int cobroId, {double? monto}) =>
      PasarelaService.crearCheckout(cobroId, tipo, monto: monto);
}
