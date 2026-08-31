import 'package:flutter/material.dart';

import '../screens/residente/pasarela_webview_screen.dart';
import '../services/flujo_pago_service.dart';

/// Fachada histórica del flujo de pago.
///
/// El contenido real se movió a [FlujoPagoService] (la secuencia) y a
/// `pasarela_selector_sheet.dart` (el bottom sheet), porque la misma lógica estaba
/// duplicada en la tarjeta de cobro del estado de cuenta y hacía falta una tercera
/// variante para pagar la deuda completa.
///
/// Se conserva solo para no romper llamadas existentes: en código nuevo usá
/// directamente `FlujoPagoService.pagarCobro` o `FlujoPagoService.pagarDeuda`.
@Deprecated('Usar FlujoPagoService.pagarCobro / FlujoPagoService.pagarDeuda')
class PasarelaSelector {
  static Future<ResultadoPago?> iniciarPago({
    required BuildContext context,
    required int cobroId,
    required String tituloCobro,
    double? monto,
  }) {
    return FlujoPagoService.pagarCobro(
      context: context,
      cobroId: cobroId,
      titulo: tituloCobro,
      monto: monto,
    );
  }
}
