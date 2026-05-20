import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';
import '../services/pasarela_service.dart';
import '../screens/residente/pasarela_webview_screen.dart';

/// Widget que orquesta la selección de pasarela y apertura del WebView de pago.
///
/// Uso:
/// ```dart
/// final resultado = await PasarelaSelector.iniciarPago(
///   context: context,
///   cobroId: cobro.id,
///   tituloCobro: cobro.concepto,
///   monto: montoOpcional,
/// );
/// ```
class PasarelaSelector {
  /// Punto de entrada principal.
  /// - Si el tenant tiene 1 pasarela activa → va directo al checkout.
  /// - Si tiene varias → muestra un bottom sheet para que el usuario elija.
  /// - Si no tiene ninguna → muestra error.
  ///
  /// Retorna [ResultadoPago] o null si no se pudo iniciar.
  static Future<ResultadoPago?> iniciarPago({
    required BuildContext context,
    required int cobroId,
    required String tituloCobro,
    double? monto,
  }) async {
    // 1. Obtener pasarelas disponibles
    List<PasarelaDisponibleModel> pasarelas;
    try {
      pasarelas = await PasarelaService.obtenerDisponibles();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener métodos de pago: $e')),
        );
      }
      return null;
    }

    if (pasarelas.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este conjunto no tiene pasarelas de pago configuradas'),
          ),
        );
      }
      return null;
    }

    // 2. Si hay solo una pasarela, ir directo; si hay varias, mostrar selector
    TipoPasarela? elegida;
    if (pasarelas.length == 1) {
      elegida = pasarelas.first.tipo;
    } else {
      if (!context.mounted) return null;
      elegida = await _mostrarSelector(context, pasarelas);
      if (elegida == null) return null; // usuario cerró el bottom sheet
    }

    // 3. Crear checkout
    if (!context.mounted) return null;
    CheckoutResponseModel checkout;
    try {
      checkout = await PasarelaService.crearCheckout(
        cobroId,
        elegida,
        monto: monto,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar el pago: $e')),
        );
      }
      return null;
    }

    // 4. Abrir WebView
    if (!context.mounted) return null;
    final resultado = await Navigator.of(context).push<ResultadoPago>(
      MaterialPageRoute(
        builder: (_) => PasarelaWebViewScreen(
          checkoutUrl: checkout.checkoutUrl,
          tipoPasarela: checkout.tipoPasarela,
          tituloCobro: tituloCobro,
        ),
        fullscreenDialog: true,
      ),
    );

    return resultado;
  }

  // ─── Bottom sheet de selección ────────────────────────────────────────────

  static Future<TipoPasarela?> _mostrarSelector(
    BuildContext context,
    List<PasarelaDisponibleModel> pasarelas,
  ) {
    return showModalBottomSheet<TipoPasarela>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PasarelaSelectorSheet(pasarelas: pasarelas),
    );
  }
}

// ─── Bottom Sheet Widget ──────────────────────────────────────────────────────

class _PasarelaSelectorSheet extends StatelessWidget {
  final List<PasarelaDisponibleModel> pasarelas;

  const _PasarelaSelectorSheet({required this.pasarelas});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Con qué pasarela quieres pagar?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige tu método de pago preferido',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...pasarelas.map((p) => _PasarelaCard(
                  pasarela: p,
                  onTap: () => Navigator.of(context).pop(p.tipo),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PasarelaCard extends StatelessWidget {
  final PasarelaDisponibleModel pasarela;
  final VoidCallback onTap;

  const _PasarelaCard({required this.pasarela, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _iconoPasarela(pasarela.tipo),
        title: Text(
          pasarela.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_subtitulo(pasarela.tipo)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _iconoPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF009EE3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.payment, color: Colors.white),
        );
      case TipoPasarela.wompi:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00C896),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.credit_card, color: Colors.white),
        );
      case TipoPasarela.bold:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bolt, color: Colors.white),
        );
    }
  }

  String _subtitulo(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return 'Tarjetas, PSE, efectivo';
      case TipoPasarela.wompi:
        return 'Tarjetas, Nequi, bancolombia';
      case TipoPasarela.bold:
        return 'Tarjetas débito y crédito';
    }
  }
}
