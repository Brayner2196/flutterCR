import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class SeccionAgrupadoraItemAccion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const SeccionAgrupadoraItemAccion({super.key,
    required this.icono,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final efectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icono, size: 20, color: efectiveColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: efectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: efectiveColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}