import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/residente_estadisticas_provider.dart';
import 'pagos/estado_cuenta_screen.dart';
import 'pagos/mis_pagos_screen.dart';
import 'reservas/mis_reservas_screen.dart';
import 'pqrs/mis_pqrs_screen.dart';
import 'widgets/banner_bienvenida.dart';
import 'widgets/deuda_resumen_widget.dart';

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
    final auth = context.watch<AuthProvider>();
    final stats = context.watch<ResidenteEstadisticasProvider>();

    return RefreshIndicator(
      onRefresh: () => stats.refrescar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BannerBienvenidaResidente(nombreUser: auth.nombre ?? 'Usuario'),
            const SizedBox(height: 16),

            // ─── Resumen financiero coloquial ───────────────
            Skeletonizer(
              enabled: stats.loading,
              child: stats.estadisticas != null
                  ? DeudaResumenWidget(
                      stats: stats.estadisticas!,
                      formatMonto: _fmt,
                      onVerEstadoCuenta: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EstadoCuentaScreen()),
                      ),
                    )
                  : stats.error != null
                      ? _buildError(stats)
                      : _buildPlaceholder(),
            ),

            const SizedBox(height: 24),

            // ─── Accesos rápidos ────────────────────────────
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                  color: Colors.green,
                  onTap: () => widget.onNavegar(1),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Estado de Cuenta',
                  icono: Icons.account_balance_wallet_outlined,
                  color: Colors.blue,
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
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MisPagosScreen()),
                  ),
                ),
                _tarjeta(
                  theme: theme,
                  label: 'Reservas',
                  icono: Icons.event_outlined,
                  color: Colors.orange,
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
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ResidenteEstadisticasProvider stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(stats.error ?? 'Error al cargar datos',
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => stats.refrescar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _tarjeta({
    required ThemeData theme,
    required String label,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
