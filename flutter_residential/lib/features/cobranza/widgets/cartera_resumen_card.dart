import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/theme/app_theme.dart';

/// Encabezado del módulo: cuánto se debe, cuántas propiedades y cuánta mora,
/// siempre referido al filtro activo (el mes o la fase que esté seleccionada).
///
/// Va antes que la lista a propósito: la primera pregunta de una gestión de
/// cobranza es "cuánto hay por recuperar", no "qué cobro sigue".
class CarteraResumenCard extends StatelessWidget {
  final double totalDeuda;
  final double totalMora;
  final int propiedades;

  /// Texto del alcance actual: "Septiembre 2026", "Todos los meses"…
  final String contexto;

  const CarteraResumenCard({
    super.key,
    required this.totalDeuda,
    required this.totalMora,
    required this.propiedades,
    required this.contexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 15, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cartera por recuperar · $contexto',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.cop(totalDeuda),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.danger,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dato(
                context,
                icono: Icons.home_work_outlined,
                texto: '$propiedades ${propiedades == 1 ? 'propiedad' : 'propiedades'}',
              ),
              const SizedBox(width: 14),
              _dato(
                context,
                icono: Icons.trending_up,
                texto: 'Mora ${CurrencyFormatter.cop(totalMora)}',
                color: AppColors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dato(BuildContext context,
      {required IconData icono, required String texto, Color? color}) {
    final c = color ?? AppColors.textMidLight;
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
