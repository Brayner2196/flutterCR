import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/shared/widgets/theme_toggle_switch.dart';

class SeccionAgrupadoraItemToogle extends StatelessWidget {
  final IconData icono;
  final String label;
  final bool valor;
  final VoidCallback onChanged;

  const SeccionAgrupadoraItemToogle({super.key,
    required this.icono,
    required this.label,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ThemeToggleSwitch(
                  isDark: valor,
                  onToggle: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}