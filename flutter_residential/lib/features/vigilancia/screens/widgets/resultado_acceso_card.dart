import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Tarjeta de resultado de una verificación de acceso (permitido / denegado /
/// advertencia). Mantiene la paleta de estados de la app.
class ResultadoAccesoCard extends StatelessWidget {
  final bool permitido;
  final bool advertencia;
  final String titulo;
  final String mensaje;
  final Map<String, String>? detalles;

  const ResultadoAccesoCard({
    super.key,
    required this.permitido,
    this.advertencia = false,
    required this.titulo,
    required this.mensaje,
    this.detalles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color fg;
    final Color bg;
    final IconData icono;
    if (advertencia) {
      fg = AppColors.warning;
      bg = AppColors.warningSoft;
      icono = Icons.info_outline_rounded;
    } else if (permitido) {
      fg = AppColors.ok;
      bg = AppColors.okSoft;
      icono = Icons.check_circle_rounded;
    } else {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
      icono = Icons.cancel_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: fg, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (mensaje.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(mensaje, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
          ],
          if (detalles != null && detalles!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...detalles!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key}: ',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(e.value,
                          style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
