import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../usuarios/providers/residente_estadisticas_provider.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import '../../pagos/screens/residente/mis_pagos_screen.dart';
import '../../reservas/screens/residente/mis_reservas_screen.dart';
import '../../pqr/screens/residente/mis_pqrs_screen.dart';
import '../../anuncios/screens/residente/mis_anuncios_screen.dart';
import '../../votaciones/screens/residente/mis_votaciones_screen.dart';
import 'widgets/banner_bienvenida.dart';
import 'widgets/deuda_resumen_widget.dart';
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
      context.read<ResidenteEstadisticasProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final stats = context.watch<ResidenteEstadisticasProvider>();

    return RefreshIndicator(
      onRefresh: () => stats.refrescar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BannerBienvenidaResidente(nombreUser: auth.nombre ?? 'Usuario'),
            const SizedBox(height: AppSpacing.md),

            // ─── Resumen financiero ─────────────────────────
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

            const SizedBox(height: AppSpacing.lg),

            // ─── Accesos rápidos ────────────────────────────
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _tarjeta(
                  theme: theme,
                  label: 'Mi Propiedad',
                  icono: Icons.home_work_outlined,
                  fg: AppColors.green,
                  bg: AppColors.bgGreen,
                  onTap: () => widget.onNavegar(1),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Estado de Cuenta',
                  icono: Icons.account_balance_wallet_outlined,
                  fg: AppColors.blue,
                  bg: AppColors.bgBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EstadoCuentaScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Mis Pagos',
                  icono: Icons.receipt_long_outlined,
                  fg: AppColors.teal,
                  bg: AppColors.bgTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MisPagosScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Reservas',
                  icono: Icons.event_outlined,
                  fg: AppColors.orange,
                  bg: AppColors.bgOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MisReservasScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'PQRs',
                  icono: Icons.support_agent_outlined,
                  fg: AppColors.purple,
                  bg: AppColors.bgPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Anuncios',
                  icono: Icons.campaign_outlined,
                  fg: AppColors.yellow,
                  bg: AppColors.bgYellow,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MisAnunciosScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Votaciones',
                  icono: Icons.how_to_vote_outlined,
                  fg: AppColors.teal,
                  bg: AppColors.bgTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MisVotacionesScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _tarjeta({
    required ThemeData theme,
    required String label,
    required IconData icono,
    required Color fg,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 36, color: fg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
