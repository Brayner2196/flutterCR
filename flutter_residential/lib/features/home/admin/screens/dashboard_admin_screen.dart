import 'package:flutter/material.dart';
import 'package:flutter_residential/features/anuncios/screens/admin/admin_anuncios_screen.dart';
import 'package:flutter_residential/features/documentos/screens/admin/admin_documentos_screen.dart';
import 'package:flutter_residential/features/dashboard/providers/dashboard_provider.dart';
import 'package:flutter_residential/features/dashboard/screens/widgets/kpi_carousel.dart';
import 'package:flutter_residential/features/home/admin/widgets/quick_access_cards.dart';
import 'package:flutter_residential/features/pagos/screens/admin/cobros_hub_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_verificar_pagos_screen.dart';
import 'package:flutter_residential/features/pqr/screens/admin/admin_pqrs_screen.dart';
import 'package:flutter_residential/features/reservas/screens/admin/admin_reservas_screen.dart';
import 'package:flutter_residential/features/votaciones/screens/admin/admin_votaciones_screen.dart';
import 'package:flutter_residential/features/plan_pago/screens/admin/admin_planes_pago_screen.dart';
import 'package:flutter_residential/features/presupuesto/screens/admin/admin_presupuestos_screen.dart';
import 'package:flutter_residential/features/parqueaderos/screens/admin/admin_parqueaderos_screen.dart';
import 'package:flutter_residential/features/consejo/screens/admin_consejo_screen.dart';
import 'package:flutter_residential/features/vigilancia/screens/admin_vigilancia_screen.dart';
import 'package:flutter_residential/core/enums/modulo.dart';
import 'package:flutter_residential/features/modulos/providers/modulos_provider.dart';
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
    // Módulos habilitados en el conjunto. Un módulo apagado no se muestra
    // deshabilitado: se oculta, porque un candado sobre algo que el conjunto
    // no contrató solo genera preguntas a la administración.
    final modulos = context.watch<ModulosProvider>();
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().refrescar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: KpiCarouselDashboard(
                // Con el módulo apagado el KPI queda sin acción en vez de
                // navegar a una pantalla que el backend va a rechazar con 403.
                onTapPqrs: modulos.activo(Modulo.pqr)
                    ? () => _abrir(const AdminPqrsScreen())
                    : null,
                onTapPagos: () => _abrir(const AdminVerificarPagosScreen()),
                onTapComprobantes: () => _abrir(const AdminVerificarPagosScreen()),
                onTapReservas: modulos.activo(Modulo.reservas)
                    ? () => _abrir(const AdminReservasScreen())
                    : null,
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
                  onTap: () => _abrir(const CobrosHubScreen()),
                ),
                if (modulos.activo(Modulo.pqr))
                  QuickAccessCardData(
                  title: 'PQRs',
                  icon: Icons.forum_outlined,
                  backgroundColor: _bgOrange,
                  iconBackgroundColor: Colors.white,
                  iconColor: _orange,
                  colorText: _orange,
                  onTap: () => _abrir(const AdminPqrsScreen()),
                ),
                if (modulos.activo(Modulo.reservas))
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
                  onTap: () => _abrir(const CobrosHubScreen(initialTab: 1)),
                ),
                if (modulos.activo(Modulo.anuncios))
                  QuickAccessCardData(
                  title: 'Anuncios',
                  icon: Icons.campaign_outlined,
                  backgroundColor: AppColors.bgYellow,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.yellow,
                  colorText: AppColors.yellow,
                  onTap: () => _abrir(const AdminAnunciosScreen()),
                ),
                if (modulos.activo(Modulo.documentos))
                  QuickAccessCardData(
                  title: 'Documentos',
                  icon: Icons.folder_copy_outlined,
                  backgroundColor: AppColors.bgBlue,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.blue,
                  colorText: AppColors.blue,
                  onTap: () => _abrir(const AdminDocumentosScreen()),
                ),
                if (modulos.activo(Modulo.votaciones))
                  QuickAccessCardData(
                  title: 'Votaciones',
                  icon: Icons.how_to_vote_outlined,
                  backgroundColor: _bgTeal,
                  iconBackgroundColor: Colors.white,
                  iconColor: _teal,
                  colorText: _teal,
                  onTap: () => _abrir(const AdminVotacionesScreen()),
                ),
                if (modulos.activo(Modulo.presupuesto))
                  QuickAccessCardData(
                  title: 'Presupuesto',
                  icon: Icons.account_balance_outlined,
                  backgroundColor: AppColors.bgGreen,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.ok,
                  colorText: AppColors.ok,
                  onTap: () => _abrir(const AdminPresupuestosScreen()),
                ),
                if (modulos.activo(Modulo.parqueaderos))
                  QuickAccessCardData(
                  title: 'Parqueaderos',
                  icon: Icons.local_parking,
                  backgroundColor: AppColors.bgBlue,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.blue,
                  colorText: AppColors.blue,
                  onTap: () => _abrir(const AdminParqueaderosScreen()),
                ),
                if (modulos.activo(Modulo.consejo))
                  QuickAccessCardData(
                  title: 'Consejo',
                  icon: Icons.gavel_rounded,
                  backgroundColor: AppColors.bgPurple,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.purple,
                  colorText: AppColors.purple,
                  onTap: () => _abrir(const AdminConsejoScreen()),
                ),
                if (modulos.activo(Modulo.planesPago))
                  QuickAccessCardData(
                  title: 'Planes de pago',
                  icon: Icons.calendar_month_outlined,
                  backgroundColor: AppColors.bgOrange,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.orange,
                  colorText: AppColors.orange,
                  onTap: () => _abrir(const AdminPlanesPagoScreen()),
                ),
                if (modulos.activo(Modulo.vigilancia))
                  QuickAccessCardData(
                  title: 'Vigilancia',
                  icon: Icons.shield_outlined,
                  backgroundColor: AppColors.bgBlue,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.blue,
                  colorText: AppColors.blue,
                  onTap: () => _abrir(const AdminVigilanciaScreen()),
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
