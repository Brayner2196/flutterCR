import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';

/// Logo visual de una pasarela de pago conocida (online).
/// Renderiza un contenedor con color de marca y texto identificador.
/// Se usa en el selector de pasarela y en los movimientos de pago.
class PasarelaLogoWidget extends StatelessWidget {
  final TipoPasarela tipo;
  final double size;

  const PasarelaLogoWidget({
    super.key,
    required this.tipo,
    this.size = 40,
  });

  Color get _color {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return const Color(0xFF009EE3);
      case TipoPasarela.wompi:
        return const Color(0xFF6C3CE1);
      case TipoPasarela.bold:
        return const Color(0xFF1AC957);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: _buildInner()),
    );
  }

  Widget _buildInner() {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return Text(
          'MP',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
          ),
        );
      case TipoPasarela.wompi:
        return Text(
          'W',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.50,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        );
      case TipoPasarela.bold:
        return Text(
          'B',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.50,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1.1,
          ),
        );
    }
  }
}

/// Icono/logo de un método de pago dado como String desde el backend.
/// Para WOMPI / MERCADO_PAGO / BOLD muestra el logo de marca.
/// Para métodos manuales muestra un icono Material genérico.
class MetodoPagoIcon extends StatelessWidget {
  final String? metodoPago;

  /// Tamaño del contenedor del logo (para pasarelas online) o del ícono (manual).
  final double size;

  const MetodoPagoIcon({super.key, this.metodoPago, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final metodo = (metodoPago ?? '').toUpperCase();

    if (metodo == 'WOMPI') {
      return PasarelaLogoWidget(tipo: TipoPasarela.wompi, size: size);
    }
    if (metodo == 'MERCADO_PAGO') {
      return PasarelaLogoWidget(tipo: TipoPasarela.mercadoPago, size: size);
    }
    if (metodo == 'BOLD') {
      return PasarelaLogoWidget(tipo: TipoPasarela.bold, size: size);
    }

    // Métodos manuales → icono genérico
    return Icon(_iconoManual(metodo), size: size, color: Colors.grey.shade500);
  }

  /// Nombre legible del método para mostrar junto al icono.
  static String nombreLegible(String? metodoPago) {
    switch ((metodoPago ?? '').toUpperCase()) {
      case 'WOMPI':
        return 'Wompi';
      case 'MERCADO_PAGO':
        return 'Mercado Pago';
      case 'BOLD':
        return 'Bold';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'CONSIGNACION':
        return 'Consignación';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return metodoPago ?? 'Pago';
    }
  }

  IconData _iconoManual(String metodo) {
    switch (metodo) {
      case 'TRANSFERENCIA':
        return Icons.account_balance_outlined;
      case 'EFECTIVO':
        return Icons.payments_outlined;
      case 'CONSIGNACION':
        return Icons.receipt_outlined;
      case 'CHEQUE':
        return Icons.description_outlined;
      default:
        return Icons.credit_card_outlined;
    }
  }
}
