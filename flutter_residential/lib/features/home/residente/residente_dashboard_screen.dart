import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../usuarios/providers/residente_estadisticas_provider.dart';
import '../../anuncios/providers/anuncio_provider.dart';
import '../../pqr/providers/pqr_provider.dart';
import '../../votaciones/providers/votacion_provider.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import '../../pagos/screens/residente/mis_pagos_screen.dart';
import '../../reservas/screens/residente/mis_reservas_screen.dart';
import '../../pqr/screens/residente/mis_pqrs_screen.dart';
import '../../anuncios/screens/residente/mis_anuncios_screen.dart';
import '../../votaciones/screens/residente/mis_votaciones_screen.dart';
import 'widgets/deuda_resumen_widget.dart';
import 'widgets/cumplimiento_card.dart';
import 'widgets/proximo_vencimiento_card.dart';
import 'widgets/quick_access_card.dart';
import 'widgets/activity_feed_widget.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class ResidenteDashboardScreen extends StatefulWidget {
  final void Function(int index) onNavegar;

  const ResidenteDashboardScreen({super.key, required this.onNavegar});

  @override
  State<ResidenteDashboardScreen> createState() =>
      _ResidenteDashboardScreenState();
}

class _ResidenteDashboardScreenState extends State<ResidenteDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar estadísticas financieras
      context.read<ResidenteEstadisticasProvider>().cargar();
      // Cargar datos para el feed y badges
      context.read<AnuncioProvider>().cargarResidente();
      context.read<PqrProvider>().cargarMisPqrs();
      context.read<VotacionProvider>().cargarResidente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stats = context.watch<ResidenteEstadisticasProvider>();
    final anuncios = context.watch<AnuncioProvider>();
    final pqrs = context.watch<PqrProvider>();
    final votaciones = context.watch<VotacionProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          stats.refrescar(),
          anuncios.cargarResidente(),
          pqrs.cargarMisPqrs(),
          votaciones.cargarResidente(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Tu situación financiera ────────────────────────────────────
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
                            builder: (_) => const EstadoCuentaScreen()),
                      ),
                    )
                  : stats.error != null
                      ? _buildError(stats, cs)
                      : _buildPlaceholder(cs),
            ),

            // ─── KPI: Próximo vencimiento ───────────────────────────────────
            if (stats.estadisticas?.proximoVencimiento != null) ...[
              const SizedBox(height: AppSpacing.md),
              ProximoVencimientoCard(
                cobro: stats.estadisticas!.proximoVencimiento!,
                diasRestantes: stats.estadisticas!.diasParaVencimiento,
                formatMonto: _fmt,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EstadoCuentaScreen()),
                ),
              ),
            ],

            // ─── KPI: Cumplimiento ──────────────────────────────────────────
            if (stats.estadisticas != null &&
                stats.estadisticas!.totalCobrosHistoricos > 0) ...[
              const SizedBox(height: AppSpacing.md),
              CumplimientoCard(
                porcentaje: stats.estadisticas!.porcentajeCumplimiento,
                pagados: stats.estadisticas!.cobrosPagados,
                total: stats.estadisticas!.totalCobrosHistoricos,
                totalPagado: stats.estadisticas!.totalPagadoHistorico,
                formatMonto: _fmt,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ─── Accesos rápidos ────────────────────────────────────────────
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildAccesos(context, anuncios, pqrs, votaciones),

            const SizedBox(height: AppSpacing.lg),

            // ─── Actividad reciente ─────────────────────────────────────────
            Text(
              'Actividad reciente',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityFeedWidget(
              ultimoPago: stats.estadisticas?.ultimoPago,
              formatMonto: _fmt,
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─── Accesos rápidos ──────────────────────────────────────────────────────

  Widget _buildAccesos(
    BuildContext context,
    AnuncioProvider anuncios,
    PqrProvider pqrs,
    VotacionProvider votaciones,
  ) {
    return Column(
      children: [
        QuickAccessCard(
          label: 'Estado de Cuenta',
          subtitulo: 'Ver cobros y deuda',
          icono: Icons.account_balance_wallet_outlined,
          fg: AppColors.blue,
          bg: AppColors.bgBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'Mis Pagos',
          subtitulo: 'Historial de pagos',
          icono: Icons.receipt_long_outlined,
          fg: AppColors.teal,
          bg: AppColors.bgTeal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MisPagosScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'Reservas',
          subtitulo: 'Áreas comunes',
          icono: Icons.event_outlined,
          fg: AppColors.orange,
          bg: AppColors.bgOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MisReservasScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'PQRs',
          subtitulo: pqrs.cantidadPendientes > 0
              ? '${pqrs.cantidadPendientes} pendiente${pqrs.cantidadPendientes == 1 ? '' : 's'}'
              : 'Sin pendientes',
          icono: Icons.support_agent_outlined,
          fg: AppColors.purple,
          bg: AppColors.bgPurple,
          badge: pqrs.cantidadPendientes > 0 ? pqrs.cantidadPendientes : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'Anuncios',
          subtitulo: anuncios.noVistos > 0
              ? '${anuncios.noVistos} nuevo${anuncios.noVistos == 1 ? '' : 's'}'
              : 'Sin novedades',
          icono: Icons.campaign_outlined,
          fg: AppColors.yellow,
          bg: AppColors.bgYellow,
          badge: anuncios.noVistos > 0 ? anuncios.noVistos : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MisAnunciosScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'Votaciones',
          subtitulo: votaciones.pendientesDeVotar > 0
              ? '${votaciones.pendientesDeVotar} ${votaciones.pendientesDeVotar == 1 ? 'votación abierta' : 'votaciones abiertas'}'
              : 'Sin votaciones activas',
          icono: Icons.how_to_vote_outlined,
          fg: AppColors.green,
          bg: AppColors.bgGreen,
          badge: votaciones.pendientesDeVotar > 0
              ? votaciones.pendientesDeVotar
              : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MisVotacionesScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickAccessCard(
          label: 'Mi Propiedad',
          subtitulo: 'Ver detalles de tu unidad',
          icono: Icons.home_work_outlined,
          fg: AppColors.blue,
          bg: AppColors.bgBlue,
          onTap: () => widget.onNavegar(2),
        ),
      ],
    );
  }

  // ─── Error / placeholder ──────────────────────────────────────────────────

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

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
