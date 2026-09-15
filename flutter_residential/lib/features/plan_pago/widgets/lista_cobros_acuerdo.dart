import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/format_moneda.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/panel_tiles.dart';
import '../models/cobro_acuerdo_model.dart';

/// Cobros del acuerdo (abono inicial + cuotas) con su estado real.
///
/// El mismo listado sirve al residente y al admin: los dos miran los mismos
/// cobros, no dos vistas distintas de la misma deuda.
class ListaCobrosAcuerdo extends StatelessWidget {
  final List<CobroAcuerdoModel> cobros;

  /// Acción opcional de pago. Sin ella el listado es solo lectura.
  final void Function(CobroAcuerdoModel cobro)? onPagar;

  const ListaCobrosAcuerdo({super.key, required this.cobros, this.onPagar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (cobros.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'El acuerdo todavía no ha generado cobros',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: cobros.map((c) => _CobroTile(cobro: c, onPagar: onPagar)).toList(),
    );
  }
}

class _CobroTile extends StatelessWidget {
  final CobroAcuerdoModel cobro;
  final void Function(CobroAcuerdoModel cobro)? onPagar;

  const _CobroTile({required this.cobro, this.onPagar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colores(cs);

    return PanelTiles(
      margin: const EdgeInsets.only(bottom: 8),
      lado: BorderSide(color: cobro.vencido ? AppColors.warning : cs.outline),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: cobro.esAbonoInicial
                    ? Icon(Icons.flag_outlined, size: 18, color: fg)
                    : Text(
                        '${cobro.numeroCuota ?? ''}',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: fg),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cobro.titulo,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _subtitulo(),
                    style: TextStyle(
                      fontSize: 11,
                      color: cobro.vencido
                          ? AppColors.warning
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(FormatMoneda.format(cobro.monto),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _estadoLegible(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
            if (onPagar != null && cobro.sePuedePagar) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => onPagar!(cobro),
                icon: const Icon(Icons.payment_outlined, size: 18),
                tooltip: 'Pagar',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitulo() {
    final fecha = cobro.fechaLimitePago == null
        ? ''
        : 'Vence ${DateFormatter.fecha(cobro.fechaLimitePago)}';
    if (cobro.esPagado) return 'Pagado';
    if (cobro.montoPagado > 0) {
      return '$fecha  ·  abonado ${FormatMoneda.format(cobro.montoPagado)}';
    }
    return cobro.vencido ? '$fecha  ·  vencida' : fecha;
  }

  String _estadoLegible() {
    switch (cobro.estado) {
      case 'PAGADO':
        return 'PAGADO';
      case 'PARCIAL':
        return 'PARCIAL';
      case 'EN_VERIFICACION':
        return 'EN REVISIÓN';
      case 'VENCIDO':
        return 'VENCIDO';
      case 'ANULADO':
        return 'ANULADO';
      case 'EXONERADO':
        return 'EXONERADO';
      default:
        return 'PENDIENTE';
    }
  }

  (Color, Color) _colores(ColorScheme cs) {
    if (cobro.esPagado) {
      return (AppColors.bgBlue, AppColors.blue);
    }
    if (cobro.esAnulado) {
      return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
    if (cobro.vencido || cobro.estado == 'VENCIDO') {
      return (AppColors.warningSoft, AppColors.warning);
    }
    return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
  }
}
