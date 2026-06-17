import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/theme/app_theme.dart';

/// Cabecera de recaudo: monto recaudado vs esperado, porcentaje y barra.
///
/// Extraída de `admin_cobros_screen` para reutilizarla en el hub y reportes.
class ResumenRecaudoHeader extends StatelessWidget {
  final double totalRecaudado;
  final double totalEsperado;

  const ResumenRecaudoHeader({
    super.key,
    required this.totalRecaudado,
    required this.totalEsperado,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = totalEsperado > 0 ? totalRecaudado / totalEsperado : 0.0;
    final colorPct = pct >= 0.9
        ? AppColors.ok
        : pct >= 0.6
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.cop(totalRecaudado),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'de ${CurrencyFormatter.cop(totalEsperado)} esperado',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorPct.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorPct,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerHighest,
              color: colorPct,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
