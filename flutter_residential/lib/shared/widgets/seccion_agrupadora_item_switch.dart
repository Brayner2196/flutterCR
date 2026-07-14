import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Ítem de una [SeccionAgrupadora] con un switch de encendido/apagado.
/// Reutilizable para cualquier preferencia booleana con label y subtítulo.
class SeccionAgrupadoraItemSwitch extends StatelessWidget {
  final IconData icono;
  final String label;
  final String? subtitle;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const SeccionAgrupadoraItemSwitch({
    super.key,
    required this.icono,
    required this.label,
    this.subtitle,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () => onChanged(!valor),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Icon(icono, size: 20, color: cs.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(value: valor, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
