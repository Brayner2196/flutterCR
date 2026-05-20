import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/residente/widgets/feed/activity_feed_widget.dart';
import 'package:flutter_residential/features/home/residente/widgets/carousel/deuda_resumen_widget.dart';
import 'package:flutter_residential/features/pagos/screens/residente/estado_cuenta_screen.dart';
import 'package:flutter_residential/features/usuarios/providers/residente_estadisticas_provider.dart';
import 'package:flutter_residential/shared/widgets/carousel.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class CarouselInfoRelevanteResidente extends StatelessWidget {
  const CarouselInfoRelevanteResidente({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ResidenteEstadisticasProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return CarouselWidget(
      pages: [
        Skeletonizer(
          enabled: stats.loading,
          child: stats.estadisticas != null
              ? DeudaResumenWidget(
                  stats: stats.estadisticas!,
                  saldoFavor: stats.saldoFavor,
                  formatMonto: _fmt,
                  onVerEstadoCuenta: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EstadoCuentaScreen(),
                    ),
                  ),
                )
              : stats.error != null
              ? _buildError(stats, cs)
              : _buildPlaceholder(cs),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad reciente',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                child: ActivityFeedWidget(
                  ultimoPago: stats.estadisticas?.ultimoPago,
                  formatMonto: _fmt,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Widget _buildError(ResidenteEstadisticasProvider stats, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stats.error ?? 'Error al cargar datos',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => stats.refrescar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}
