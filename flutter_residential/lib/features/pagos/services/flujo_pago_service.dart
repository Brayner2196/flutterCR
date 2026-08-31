import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/platform/checkout_web.dart';
import '../models/pasarela_disponible_model.dart';
import '../screens/residente/pasarela_webview_screen.dart';
import '../widgets/pasarela_selector_sheet.dart';
import 'pasarela_service.dart';

/// Firma de "pedile el link de pago al backend con esta pasarela".
///
/// Es lo único que cambia entre pagar un cobro y pagar toda la deuda; todo lo demás
/// (elegir pasarela, abrir el checkout, interpretar el regreso) es idéntico.
typedef CrearCheckout = Future<CheckoutResponseModel> Function(TipoPasarela);

/// El camino que recorre un pago: pasarelas disponibles → elección → checkout → regreso.
///
/// Esa secuencia estaba escrita dos veces, en `PasarelaSelector` y dentro de la tarjeta
/// de cobro del estado de cuenta, con diferencias sutiles entre ambas (una mostraba
/// "Recomendado", la otra no; una manejaba el caso web, la otra a medias). Con el flujo
/// en un solo lugar, agregar la tercera forma de pagar —la deuda completa— fue pasar
/// una función distinta, no copiar el bloque una tercera vez.
class FlujoPagoService {

  /// Paga UN cobro. El dinero se aplica a ese cobro; si sobra, el backend lo baja al resto.
  static Future<ResultadoPago?> pagarCobro({
    required BuildContext context,
    required int cobroId,
    required String titulo,
    double? monto,
  }) {
    return _ejecutar(
      context: context,
      titulo: titulo,
      crearCheckout: (pasarela) =>
          PasarelaService.crearCheckout(cobroId, pasarela, monto: monto),
    );
  }

  /// Paga TODA la deuda de una propiedad. El backend reparte por FIFO.
  static Future<ResultadoPago?> pagarDeuda({
    required BuildContext context,
    required int propiedadId,
    required String titulo,
    double? monto,
  }) {
    return _ejecutar(
      context: context,
      titulo: titulo,
      crearCheckout: (pasarela) =>
          PasarelaService.crearCheckoutDeuda(propiedadId, pasarela, monto: monto),
    );
  }

  // ─── El flujo, una sola vez ───────────────────────────────────────────────

  static Future<ResultadoPago?> _ejecutar({
    required BuildContext context,
    required String titulo,
    required CrearCheckout crearCheckout,
  }) async {
    final pasarela = await _elegirPasarela(context);
    if (pasarela == null) return null;

    if (!context.mounted) return null;
    CheckoutResponseModel checkout;
    try {
      checkout = await crearCheckout(pasarela);
    } catch (e) {
      if (!context.mounted) return null;
      _avisar(context, _limpiarError(e));
      return null;
    }

    if (!context.mounted) return null;
    return _abrirCheckout(context, checkout, titulo);
  }

  /// Si el conjunto tiene una sola pasarela activa no vale la pena preguntar.
  static Future<TipoPasarela?> _elegirPasarela(BuildContext context) async {
    List<PasarelaDisponibleModel> pasarelas;
    try {
      pasarelas = await PasarelaService.obtenerDisponibles();
    } catch (_) {
      if (!context.mounted) return null;
      _avisar(context, 'No se pudieron cargar los métodos de pago');
      return null;
    }

    if (!context.mounted) return null;

    if (pasarelas.isEmpty) {
      _avisar(context, 'Este conjunto no tiene pasarelas de pago configuradas');
      return null;
    }
    if (pasarelas.length == 1) return pasarelas.first.tipo;

    return mostrarSelectorPasarela(context, pasarelas);
  }

  /// En móvil el checkout va en un WebView propio; en web hay que salir a otra pestaña
  /// y esperar a que el usuario la cierre, porque la pasarela no se deja embeber.
  static Future<ResultadoPago?> _abrirCheckout(
    BuildContext context,
    CheckoutResponseModel checkout,
    String titulo,
  ) async {
    if (kIsWeb) {
      final completer = Completer<void>();
      final abierto = await abrirYEsperarRegreso(
        checkout.checkoutUrl,
        () async => completer.complete(),
      );
      if (!abierto) {
        if (!context.mounted) return null;
        _avisar(context, 'No se pudo abrir la pasarela de pago');
        return null;
      }
      await completer.future;
      // La pestaña se cerró, pero la confirmación puede seguir en camino.
      return ResultadoPago.procesando;
    }

    return Navigator.of(context).push<ResultadoPago>(
      MaterialPageRoute(
        builder: (_) => PasarelaWebViewScreen(
          checkoutUrl: checkout.checkoutUrl,
          tipoPasarela: checkout.tipoPasarela,
          tituloCobro: titulo,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static void _avisar(BuildContext context, String mensaje) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  static String _limpiarError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
