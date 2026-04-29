import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/residente_estadisticas_provider.dart';
import 'pagos/estado_cuenta_screen.dart';
import 'pagos/mis_cobros_screen.dart';
import 'pagos/mis_pagos_screen.dart';
import 'reservas/mis_reservas_screen.dart';
import 'pqrs/mis_pqrs_screen.dart';
import 'widgets/banner_bienvenida.dart';
import 'widgets/estado_badge_card.dart';
import 'widgets/kpi_card.dart';
import 'widgets/proximo_vencimiento_card.dart';
import 'widgets/cumplimiento_card.dart';
import 'widgets/resumen_pagos_card.dart';

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

            // ─── Estado financiero ──────────────────────────
            Skeletonizer(
              enabled: stats.loading,
              child: stats.estadisticas != null
                  ? _buildFinanciero(theme, stats)
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

  Widget _buildFinanciero(
      ThemeData theme, ResidenteEstadisticasProvider stats) {
    final e = stats.estadisticas!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado general (al día / en mora / pendiente)
        EstadoBadgeCard(
          alDia: e.alDia,
          enMora: e.enMora,
          totalDeuda: e.totalDeuda,
          cobrosPendientes: e.cobrosPendientes,
          cobrosVencidos: e.cobrosVencidos,
          formatMonto: _fmt,
        ),
        const SizedBox(height: 12),

        // KPIs en grid 2x2
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            KpiCard(
              label: 'Pendiente',
              valor: _fmt(e.totalPendiente),
              icono: Icons.schedule_rounded,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisCobrosScreen()),
              ),
            ),
            KpiCard(
              label: 'Vencido',
              valor: _fmt(e.totalVencido),
              icono: Icons.warning_amber_rounded,
              color: Colors.red,
              subtitulo: e.totalMora > 0 ? 'Mora: ${_fmt(e.totalMora)}' : null,
            ),
            KpiCard(
              label: 'Pagos verificados',
              valor: '${e.pagosVerificados}',
              icono: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisPagosScreen()),
              ),
            ),
            KpiCard(
              label: 'Por verificar',
              valor: '${e.pagosPendientesVerificacion}',
              icono: Icons.hourglass_top_rounded,
              color: const Color(0xFF5479E0),
              subtitulo: e.ultimoPago != null
                  ? 'Último: ${e.ultimoPago!.fechaPago}'
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Próximo vencimiento
        if (e.proximoVencimiento != null) ...[
          ProximoVencimientoCard(
            cobro: e.proximoVencimiento!,
            diasRestantes: e.diasParaVencimiento,
            formatMonto: _fmt,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MisCobrosScreen()),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Cumplimiento
        if (e.totalCobrosHistoricos > 0)
          CumplimientoCard(
            porcentaje: e.porcentajeCumplimiento,
            pagados: e.cobrosPagados,
            total: e.totalCobrosHistoricos,
            totalPagado: e.totalPagadoHistorico,
            formatMonto: _fmt,
          ),

        if (e.totalPagos > 0) ...[
          const SizedBox(height: 12),
          ResumenPagosCard(
            verificados: e.pagosVerificados,
            pendientes: e.pagosPendientesVerificacion,
            rechazados: e.pagosRechazados,
            metodoFavorito: _metodoFavorito(e.pagosPorMetodo),
          ),
        ],
      ],
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
    // Placeholder para el skeletonizer
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _metodoFavorito(Map<String, int> metodos) {
    if (metodos.isEmpty) return null;
    return metodos.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
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
