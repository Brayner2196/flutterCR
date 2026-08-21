import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class SeccionAgrupadoraItemAccion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final bool isCerrarSesion;

  const SeccionAgrupadoraItemAccion({super.key,
    required this.icono,
    required this.label,
    this.color,
    required this.onTap,
    this.isCerrarSesion=false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

  final Color backgroundColor =
        isCerrarSesion ? Colors.red : Colors.transparent;
    final Color contentColor = isCerrarSesion
        ? theme.colorScheme.onError
        : (color ?? theme.colorScheme.onSurface);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icono, size: 20, color: contentColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: contentColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}