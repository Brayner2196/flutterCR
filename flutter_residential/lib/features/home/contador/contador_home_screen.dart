import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_navigation_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contador/providers/permisos_contables_provider.dart';
import '../../pagos/screens/admin/admin_verificar_pagos_screen.dart';
import '../../pagos/screens/admin/cobros_hub_screen.dart';
import '../admin/app_bar_admin.dart';
import '../admin/screens/perfil_admin_screen.dart';
import 'dashboard_contador_screen.dart';
import 'widgets/contador_sin_alcance.dart';

/// Home del rol CONTADOR.
///
/// No es la home del admin con cosas ocultas: es una pantalla propia, porque el
/// contador no administra usuarios ni propiedades. Lo suyo es dinero.
///
/// ## Las pestañas se arman en tiempo de ejecución
///
/// Cada pestaña declara los permisos que la justifican y solo entra al
/// [IndexedStack] si el usuario tiene alguno. Un contador con permiso de ver
/// cobros pero no de ver pagos abre la app con tres pestañas, no con cuatro y
/// una vacía.
///
/// Por eso el índice se guarda como POSICIÓN de la lista construida, no como un
/// número fijo: si el administrador le revoca un permiso mientras la app está
/// abierta, la lista se acorta y el `clamp` evita el índice fuera de rango.
class ContadorHomeScreen extends StatefulWidget {
  const ContadorHomeScreen({super.key});

  @override
  State<ContadorHomeScreen> createState() => _ContadorHomeScreenState();
}

class _ContadorHomeScreenState extends State<ContadorHomeScreen> {
  int _tabActual = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final permisos = context.watch<PermisosContablesProvider>();
    final cs = Theme.of(context).colorScheme;

    final appBar = AppBarAdmin(
      auth: auth,
      cs: cs,
      habilitarlogout: true,
      habilitarReturnScreen: true,
    );

    // Contador creado pero sin permisos: la cuenta existe y puede entrar, pero
    // no hay nada que mostrarle. Un mensaje explícito evita que reporte la app
    // como rota cuando en realidad falta que el administrador termine el alta.
    if (permisos.sinAlcance) {
      return Scaffold(
        appBar: appBar,
        body: const ContadorSinAlcance(),
      );
    }

    final tabs = _tabsDisponibles(permisos);
    final indice = _tabActual.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(
        index: indice,
        children: tabs.map((t) => t.pantalla).toList(),
      ),
      bottomNavigationBar: AppNavigationBar(
        tabActual: indice,
        onTabChanged: (i) => setState(() => _tabActual = i),
        colorScheme: cs,
        items: tabs.map((t) => t.item).toList(),
      ),
    );
  }

  /// Pestañas que el usuario puede ver, en orden fijo. El perfil va siempre:
  /// es donde cierra sesión, así que nunca puede quedar fuera.
  List<_TabContador> _tabsDisponibles(PermisosContablesProvider permisos) {
    final tabs = <_TabContador>[];

    if (permisos.puedeAlguno(const [
      'VER_DASHBOARD',
      'VER_COBROS',
      'VER_CARTERA',
    ])) {
      tabs.add(const _TabContador(
        item: AppNavItem(
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          label: 'Cartera',
        ),
        pantalla: DashboardContadorScreen(),
      ));
    }

    if (permisos.puede('VER_COBROS')) {
      tabs.add(const _TabContador(
        item: AppNavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Cobros',
        ),
        pantalla: CobrosHubScreen(embebida: true),
      ));
    }

    if (permisos.puedeAlguno(const ['VER_PAGOS', 'VER_ABONOS'])) {
      tabs.add(const _TabContador(
        item: AppNavItem(
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check,
          label: 'Recaudo',
        ),
        pantalla: AdminVerificarPagosScreen(embebida: true),
      ));
    }

    tabs.add(const _TabContador(
      item: AppNavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        label: 'Perfil',
      ),
      pantalla: PerfilAdminScreen(),
    ));

    return tabs;
  }
}

/// Una pestaña de la home: qué se ve abajo y qué se pinta arriba.
class _TabContador {
  final AppNavItem item;
  final Widget pantalla;

  const _TabContador({required this.item, required this.pantalla});
}
