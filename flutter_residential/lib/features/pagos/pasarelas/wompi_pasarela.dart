import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';
import '../services/pasarela_service.dart';
import 'pasarela_pago.dart';

/// Implementación de [PasarelaPago] para Wompi Payment Links.
///
/// Equivalente a WompiServiceImpl en Spring Boot.
class WompiPasarela implements PasarelaPago {
  const WompiPasarela();

  @override
  TipoPasarela get tipo => TipoPasarela.wompi;

  @override
  String get nombre => 'Wompi';

  @override
  Color get color => const Color(0xFF00C896);

  @override
  IconData get icono => Icons.credit_card;

  @override
  String get descripcion => 'Tarjetas, Nequi, Bancolombia';

  @override
  Future<CheckoutResponseModel> crearCheckout(int cobroId, {double? monto}) =>
      PasarelaService.crearCheckout(cobroId, tipo, monto: monto);
}
