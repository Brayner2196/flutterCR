import 'package:flutter/material.dart';
import 'package:flutter_residential/screens/home/admin/appBar/app_bar_admin.dart';
import 'package:flutter_residential/screens/home/admin/bottomNavigationBar/bottom_navigation_bar_admin.dart';
import 'package:flutter_residential/screens/home/admin/screens/pagos/admin_cobros_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/pagos/admin_configurar_cuotas_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/pagos/admin_reporte_morosidad_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/pagos/admin_verificar_pagos_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/pqr/admin_pqrs_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/reservas/admin_reservas_screen.dart';
import 'package:flutter_residential/screens/home/admin/screens/usuarios/usuarios_screen.dart';
import 'package:flutter_residential/screens/home/admin/widgets/dashboard/admin_dashboard.dart';
import 'package:flutter_residential/screens/home/admin/widgets/quick_access_cards.dart';
import 'package:flutter_residential/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabActual = 0;

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
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBarAdmin(auth: auth, cs: cs, habilitarlogout: true),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().refrescar(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Hola, ${auth.nombre}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AdminDashboard(
                  onTapComprobantes: () => _abrir(const AdminVerificarPagosScreen()),
                  onTapPqrs: () => _abrir(const AdminPqrsScreen()),
                  onTapReservas: () => _abrir(const AdminReservasScreen()),
                  onTapPagos: () => _abrir(const AdminVerificarPagosScreen()),
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
                    title: 'Gestionar Usuarios',
                    icon: Icons.groups,
                    backgroundColor: AppColors.bgBlue,
                    iconBackgroundColor: Colors.white,
                    iconColor: AppColors.blue,
                    colorText: AppColors.blue,
                    onTap: () => _abrir(const UsuariosScreen()),
                  ),
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
                    title: 'Verificar Pagos',
                    icon: Icons.task_alt,
                    backgroundColor: AppColors.bgPurple,
                    iconBackgroundColor: Colors.white,
                    iconColor: AppColors.purple,
                    colorText: AppColors.purple,
                    onTap: () => _abrir(const AdminVerificarPagosScreen()),
                  ),
                  QuickAccessCardData(
                    title: 'PQRs',
                    icon: Icons.forum_outlined,
                    backgroundColor: _bgTeal,
                    iconBackgroundColor: Colors.white,
                    iconColor: _teal,
                    colorText: _teal,
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
                    title: 'Configurar Cuotas',
                    icon: Icons.tune,
                    backgroundColor: _bgOrange,
                    iconBackgroundColor: Colors.white,
                    iconColor: _orange,
                    colorText: _orange,
                    onTap: () => _abrir(const AdminConfigurarCuotasScreen()),
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
                    title: 'Crear Anuncio',
                    icon: Icons.campaign_outlined,
                    backgroundColor: AppColors.bgYellow,
                    iconBackgroundColor: Colors.white,
                    iconColor: AppColors.yellow,
                    colorText: AppColors.yellow,
                    onTap: () => setState(() => _tabActual = 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarAdmin(
        tabActual: _tabActual,
        onTabChanged: (i) => setState(() => _tabActual = i),
        colorScheme: cs,
      ),
    );
  }
}
