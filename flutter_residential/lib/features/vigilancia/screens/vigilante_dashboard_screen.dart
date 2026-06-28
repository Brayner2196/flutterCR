import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/residente/widgets/quick_access_card.dart';
import '../providers/vigilancia_provider.dart';

/// Inicio del vigilante: saludo, resumen de pendientes y accesos rápidos.
/// Reutiliza [QuickAccessCard] del área de residente para mantener el estilo.
class VigilanteDashboardScreen extends StatelessWidget {
  final void Function(int index) onNavegar;

  const VigilanteDashboardScreen({super.key, required this.onNavegar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<VigilanciaProvider>();
    final nombre = (auth.nombre ?? 'Vigilante').split(' ').first;

    return RefreshIndicator(
      onRefresh: () => prov.cargarResumen(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Hola, $nombre',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Panel de portería',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Resumen: paquetes pendientes ──
          _ResumenPaquetes(
            total: prov.totalPendientes,
            onTap: () => onNavegar(2),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Acciones',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),

          QuickAccessCard(
            label: 'Control de acceso',
            subtitulo: 'Placa, peatonal y QR de visitas',
            icono: Icons.qr_code_scanner_rounded,
            fg: AppColors.blue,
            bg: AppColors.bgBlue,
            onTap: () => onNavegar(1),
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickAccessCard(
            label: 'Paquetería',
            subtitulo: 'Recibir y entregar correspondencia',
            icono: Icons.inventory_2_rounded,
            fg: AppColors.orange,
            bg: AppColors.bgOrange,
            badge: prov.totalPendientes,
            onTap: () => onNavegar(2),
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickAccessCard(
            label: 'Bitácora',
            subtitulo: 'Minuta de novedades del turno',
            icono: Icons.fact_check_rounded,
            fg: AppColors.teal,
            bg: AppColors.bgTeal,
            onTap: () => onNavegar(3),
          ),
        ],
      ),
    );
  }
}

class _ResumenPaquetes extends StatelessWidget {
  final int total;
  final VoidCallback onTap;

  const _ResumenPaquetes({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgYellow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: AppColors.yellow),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paquetes por entregar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.yellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0 ? 'Sin pendientes' : '$total pendiente(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.yellow.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$total',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
