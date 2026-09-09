import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/modulo.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/quick_access_cards.dart';
import '../../cartera/screens/admin_estados_cartera_screen.dart';
import '../../contador/providers/permisos_contables_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/widgets/kpi_carousel.dart';
import '../../modulos/providers/modulos_provider.dart';
import '../../pagos/screens/admin/admin_configurar_cuotas_screen.dart';
import '../../pagos/screens/admin/admin_configurar_mora_screen.dart';
import '../../pagos/screens/admin/admin_pasarelas_screen.dart';
import '../../pagos/screens/admin/admin_reporte_morosidad_screen.dart';
import '../../pagos/screens/admin/admin_verificar_pagos_screen.dart';
import '../../pagos/screens/admin/cobros_hub_screen.dart';
import '../../plan_pago/screens/admin/admin_planes_pago_screen.dart';
import '../../presupuesto/screens/admin/admin_presupuestos_screen.dart';

/// Panel de entrada del contador: los indicadores de plata arriba y los accesos
/// a lo que su alcance le permite abajo.
///
/// Cada acceso está condicionado por un permiso. Igual que con los módulos
/// apagados en el dashboard del admin, lo que no se puede usar **se oculta** en
/// vez de mostrarse deshabilitado: un candado sobre algo que el administrador
/// decidió no darle solo genera preguntas.
class DashboardContadorScreen extends StatefulWidget {
  const DashboardContadorScreen({super.key});

  @override
  State<DashboardContadorScreen> createState() => _DashboardContadorScreenState();
}

class _DashboardContadorScreenState extends State<DashboardContadorScreen> {
  Future<T?> _abrir<T>(Widget pantalla) async {
    final res = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    if (mounted) context.read<DashboardProvider>().refrescar();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final permisos = context.watch<PermisosContablesProvider>();
    final modulos = context.watch<ModulosProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().refrescar(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (permisos.puede('VER_DASHBOARD'))
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: KpiCarouselDashboard(
                  // Sin permiso de ver pagos el KPI queda sin acción, en vez de
                  // navegar a una pantalla que el backend rechaza con 403.
                  onTapPagos: permisos.puede('VER_PAGOS')
                      ? () => _abrir(const AdminVerificarPagosScreen())
                      : null,
                  onTapComprobantes: permisos.puede('VER_PAGOS')
                      ? () => _abrir(const AdminVerificarPagosScreen())
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
            QuickAccessGrid(cards: _accesos(permisos, modulos)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Los accesos que el alcance del contador habilita. El orden va de lo más
  /// cotidiano (cobros, recaudo) a lo esporádico (parametrización).
  List<QuickAccessCardData> _accesos(
    PermisosContablesProvider permisos,
    ModulosProvider modulos,
  ) {
    return [
      if (permisos.puede('VER_COBROS'))
        QuickAccessCardData(
          title: 'Cobros',
          icon: Icons.credit_card,
          backgroundColor: AppColors.bgGreen,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.green,
          colorText: AppColors.green,
          onTap: () => _abrir(const CobrosHubScreen()),
        ),
      if (permisos.puedeAlguno(const ['VER_PAGOS', 'VER_ABONOS']))
        QuickAccessCardData(
          title: 'Recaudo',
          icon: Icons.fact_check_outlined,
          backgroundColor: AppColors.bgBlue,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.blue,
          colorText: AppColors.blue,
          onTap: () => _abrir(const AdminVerificarPagosScreen()),
        ),
      if (permisos.puede('VER_CARTERA'))
        QuickAccessCardData(
          title: 'Morosidad',
          icon: Icons.trending_down,
          backgroundColor: AppColors.bgOrange,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.orange,
          colorText: AppColors.orange,
          onTap: () => _abrir(const AdminReporteMorosidadScreen()),
        ),
      if (permisos.puede('GESTIONAR_PLANES_PAGO') && modulos.activo(Modulo.planesPago))
        QuickAccessCardData(
          title: 'Planes de pago',
          icon: Icons.handshake_outlined,
          backgroundColor: AppColors.bgPurple,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.purple,
          colorText: AppColors.purple,
          onTap: () => _abrir(const AdminPlanesPagoScreen()),
        ),
      if (permisos.puede('CONFIGURAR_CUOTAS'))
        QuickAccessCardData(
          title: 'Cuotas',
          icon: Icons.tune,
          backgroundColor: AppColors.bgGreen,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.green,
          colorText: AppColors.green,
          onTap: () => _abrir(const AdminConfigurarCuotasScreen()),
        ),
      if (permisos.puede('CONFIGURAR_MORA'))
        QuickAccessCardData(
          title: 'Mora',
          icon: Icons.percent,
          backgroundColor: AppColors.bgOrange,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.orange,
          colorText: AppColors.orange,
          onTap: () => _abrir(const AdminConfigurarMoraScreen()),
        ),
      if (permisos.puede('CONFIGURAR_CARTERA'))
        QuickAccessCardData(
          title: 'Estados de cartera',
          icon: Icons.rule_folder_outlined,
          backgroundColor: AppColors.bgBlue,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.blue,
          colorText: AppColors.blue,
          onTap: () => _abrir(const AdminEstadosCarteraScreen()),
        ),
      if (permisos.puede('CONFIGURAR_PASARELAS'))
        QuickAccessCardData(
          title: 'Pasarelas',
          icon: Icons.account_balance_outlined,
          backgroundColor: AppColors.bgPurple,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.purple,
          colorText: AppColors.purple,
          onTap: () => _abrir(const AdminPasarelasScreen()),
        ),
      if (permisos.puede('GESTIONAR_PRESUPUESTO') && modulos.activo(Modulo.presupuesto))
        QuickAccessCardData(
          title: 'Presupuesto',
          icon: Icons.pie_chart_outline,
          backgroundColor: AppColors.bgGreen,
          iconBackgroundColor: Colors.white,
          iconColor: AppColors.green,
          colorText: AppColors.green,
          onTap: () => _abrir(const AdminPresupuestosScreen()),
        ),
    ];
  }
}
