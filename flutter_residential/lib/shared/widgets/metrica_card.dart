import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta de métrica que además actúa como filtro: número grande, icono y
/// etiqueta, con borde resaltado cuando está seleccionada o en alerta.
///
/// Extraída de `EstadoResumenGrid` (Cobros), que la tenía como clase privada
/// acoplada a los estados de cobro. Cobranza cuenta otras cosas (vencidos, en
/// mora, críticos) y con esto reutiliza la misma pieza visual.
class MetricaCard extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final IconData icono;
  final Color color;
  final bool seleccionado;

  /// Resalta el borde aunque no esté seleccionada (p. ej. vencidos > 0).
  final bool alerta;

  final VoidCallback onTap;

  const MetricaCard({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bordeColor = seleccionado
        ? color
        : alerta
            ? color.withValues(alpha: 0.5)
            : cs.outline;

    return Material(
      color: seleccionado ? color.withValues(alpha: 0.08) : cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: bordeColor,
              width: seleccionado ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$valor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Icon(icono, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
