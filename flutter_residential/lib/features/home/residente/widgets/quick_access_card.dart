import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Tarjeta de acceso rápido reutilizable con badge numérico opcional
/// y subtítulo de contexto. Reemplaza el método _tarjeta() inline.
class QuickAccessCard extends StatelessWidget {
  final String label;
  final String? subtitulo;
  final IconData icono;
  final Color fg;
  final Color bg;
  final int? badge;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.label,
    this.subtitulo,
    required this.icono,
    required this.fg,
    required this.bg,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tieneBadge = badge != null && badge! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icono, size: 22, color: fg),
            ),
            const SizedBox(width: AppSpacing.md),

            // Label + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge
            if (tieneBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: fg.withValues(alpha: 0.4),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
