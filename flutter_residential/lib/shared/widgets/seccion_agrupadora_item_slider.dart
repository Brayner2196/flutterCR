import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Ítem de una [SeccionAgrupadora] con un slider numérico.
/// Reutilizable para cualquier valor entero configurable con label y valor visible.
class SeccionAgrupadoraItemSlider extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valorTexto;
  final double valor;
  final double min;
  final double max;
  final int divisions;
  final String? etiquetaSlider;
  final ValueChanged<double> onChanged;

  const SeccionAgrupadoraItemSlider({
    super.key,
    required this.icono,
    required this.label,
    required this.valorTexto,
    required this.valor,
    required this.min,
    required this.max,
    required this.divisions,
    this.etiquetaSlider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: cs.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                valorTexto,
                style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
              ),
            ],
          ),
          Slider(
            value: valor,
            min: min,
            max: max,
            divisions: divisions,
            label: etiquetaSlider,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
