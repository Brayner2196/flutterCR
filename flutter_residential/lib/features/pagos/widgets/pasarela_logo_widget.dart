import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';

/// Logo de una pasarela de pago usando el asset PNG de marca.
/// Se usa en el selector de pasarela y en los movimientos de pago.
class PasarelaLogoWidget extends StatelessWidget {
  final TipoPasarela tipo;
  final double size;

  const PasarelaLogoWidget({
    super.key,
    required this.tipo,
    this.size = 44,
  });

  String get _assetPath {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return 'assets/icons/icono_mp.png';
      case TipoPasarela.wompi:
        return 'assets/icons/icono_wompi_black.png';
      case TipoPasarela.bold:
        return 'assets/icons/logo_bold.png';
    }
  }

  Color get _fallbackColor {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return const Color(0xFF009EE3);
      case TipoPasarela.wompi:
        return const Color(0xFF6C3CE1);
      case TipoPasarela.bold:
        return const Color(0xFF1AB938);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          _assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Fallback si el asset falla por alguna razón
          errorBuilder: (_, __, ___) => _FallbackLogo(
            color: _fallbackColor,
            label: tipo.nombreLegible,
            size: size,
          ),
        ),
      ),
    );
  }
}

/// Fallback minimalista si el asset PNG no carga.
class _FallbackLogo extends StatelessWidget {
  final Color color;
  final String label;
  final double size;
  const _FallbackLogo({required this.color, required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = label.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
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
