import 'package:flutter/material.dart';
import 'package:flutter_residential/features/anuncios/screens/admin/admin_anuncios_screen.dart';
import 'package:flutter_residential/features/dashboard/providers/dashboard_provider.dart';
import 'package:flutter_residential/features/dashboard/screens/widgets/kpi_carousel.dart';
import 'package:flutter_residential/features/home/admin/widgets/quick_access_cards.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_cobros_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_configurar_cuotas_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_reporte_morosidad_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_verificar_pagos_screen.dart';
import 'package:flutter_residential/features/pqr/screens/admin/admin_pqrs_screen.dart';
import 'package:flutter_residential/features/reservas/screens/admin/admin_reservas_screen.dart';
import 'package:flutter_residential/features/votaciones/screens/admin/admin_votaciones_screen.dart';
import 'package:flutter_residential/features/plan_pago/screens/admin/admin_planes_pago_screen.dart';
import 'package:flutter_residential/features/presupuesto/screens/admin/admin_presupuestos_screen.dart';
import 'package:flutter_residential/features/parqueaderos/screens/admin/admin_parqueaderos_screen.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {

  static const _bgTeal = Color.fromRGBO(224, 247, 244, 1);
  static const _teal = Color.fromRGBO(0, 105, 92, 1);
  static const _bgOrange = Color.fromRGBO(255, 237, 224, 1);
  static const _orange = Color.fromRGBO(180, 80, 0, 1);

  Future<T?> _abrir<T>(Widget pantalla) async {
    final res = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    if (mounted) {
      context.read<DashboardProvider>().refrescar();
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().refrescar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: KpiCarouselDashboard(
                onTapPqrs: () => _abrir(const AdminPqrsScreen()),
                onTapPagos: () => _abrir(const AdminVerificarPagosScreen()),
                onTapComprobantes: () => _abrir(const AdminVerificarPagosScreen()),
                onTapReservas: () => _abrir(const AdminReservasScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCESOS RÁPIDOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            QuickAccessGrid(
              cards: [
                QuickAccessCardData(
                  title: 'Cobros',
                  icon: Icons.credit_card,
                  backgroundColor: AppColors.bgGreen,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.green,
                  colorText: AppColors.green,
                  onTap: () => _abrir(const AdminCobrosScreen()),
                ),
                QuickAccessCardData(
                  title: 'PQRs',
                  icon: Icons.forum_outlined,
                  backgroundColor: _bgOrange,
                  iconBackgroundColor: Colors.white,
                  iconColor: _orange,
                  colorText: _orange,
                  onTap: () => _abrir(const AdminPqrsScreen()),
                ),
                QuickAccessCardData(
                  title: 'Reservas',
                  icon: Icons.event_available,
                  backgroundColor: AppColors.bgYellow,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.yellow,
                  colorText: AppColors.yellow,
                  onTap: () => _abrir(const AdminReservasScreen()),
                ),
                QuickAccessCardData(
                  title: 'Reporte Morosidad',
                  icon: Icons.warning_amber_rounded,
                  backgroundColor: AppColors.bgYellow,
                  iconBackgroundColor: Colors.white,
                  iconColor: _orange,
                  colorText: _orange,
                  onTap: () => _abrir(const AdminReporteMorosidadScreen()),
                ),
                QuickAccessCardData(
                  title: 'Anuncios',
                  icon: Icons.campaign_outlined,
                  backgroundColor: AppColors.bgYellow,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.yellow,
                  colorText: AppColors.yellow,
                  onTap: () => _abrir(const AdminAnunciosScreen()),
                ),
                QuickAccessCardData(
                  title: 'Votaciones',
                  icon: Icons.how_to_vote_outlined,
                  backgroundColor: _bgTeal,
                  iconBackgroundColor: Colors.white,
                  iconColor: _teal,
                  colorText: _teal,
                  onTap: () => _abrir(const AdminVotacionesScreen()),
                ),
                QuickAccessCardData(
                  title: 'Planes de pago',
                  icon: Icons.calendar_month_outlined,
                  backgroundColor: AppColors.bgOrange,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.orange,
                  colorText: AppColors.orange,
                  onTap: () => _abrir(const AdminPlanesPagoScreen()),
                ),
                QuickAccessCardData(
                  title: 'Presupuesto',
                  icon: Icons.account_balance_outlined,
                  backgroundColor: AppColors.bgGreen,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.ok,
                  colorText: AppColors.ok,
                  onTap: () => _abrir(const AdminPresupuestosScreen()),
                ),
                QuickAccessCardData(
                  title: 'Parqueaderos',
                  icon: Icons.local_parking,
                  backgroundColor: AppColors.bgBlue,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.blue,
                  colorText: AppColors.blue,
                  onTap: () => _abrir(const AdminParqueaderosScreen()),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
