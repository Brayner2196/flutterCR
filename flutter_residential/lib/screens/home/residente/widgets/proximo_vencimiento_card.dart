import 'package:flutter/material.dart';
import '../../../../models/cobro_model.dart';

/// Card que muestra el próximo cobro por vencer con countdown de días.
class ProximoVencimientoCard extends StatelessWidget {
  final CobroModel cobro;
  final int? diasRestantes;
  final String Function(double) formatMonto;
  final VoidCallback? onTap;

  const ProximoVencimientoCard({
    super.key,
    required this.cobro,
    this.diasRestantes,
    required this.formatMonto,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool vencido = diasRestantes != null && diasRestantes! < 0;
    final bool urgente = diasRestantes != null && diasRestantes! <= 5 && !vencido;
    final Color color = vencido
        ? Colors.red
        : urgente
            ? Colors.orange
            : const Color(0xFF5479E0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (diasRestantes != null) ...[
                    Text(
                      vencido
                          ? '${diasRestantes!.abs()}'
                          : '$diasRestantes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      vencido ? 'atrás' : 'días',
                      style: TextStyle(fontSize: 9, color: color),
                    ),
                  ] else
                    Icon(Icons.calendar_today, color: color, size: 20),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vencido ? 'Cobro vencido' : 'Próximo vencimiento',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cobro.concepto,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Vence: ${cobro.fechaLimitePago}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatMonto(cobro.montoTotal),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
