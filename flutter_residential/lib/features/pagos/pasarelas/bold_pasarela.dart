import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';
import '../services/pasarela_service.dart';
import 'pasarela_pago.dart';

/// Implementación de [PasarelaPago] para Bold Payment Links.
///
/// Equivalente a BoldServiceImpl en Spring Boot.
class BoldPasarela implements PasarelaPago {
  const BoldPasarela();

  @override
  TipoPasarela get tipo => TipoPasarela.bold;

  @override
  String get nombre => 'Bold';

  @override
  Color get color => const Color(0xFF1A1A2E);

  @override
  IconData get icono => Icons.bolt;

  @override
  String get descripcion => 'Tarjetas débito y crédito';

  @override
  Future<CheckoutResponseModel> crearCheckout(int cobroId, {double? monto}) =>
      PasarelaService.crearCheckout(cobroId, tipo, monto: monto);
}
