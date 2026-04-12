import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tenant_provider.dart';
import 'super_admin_dashboard_screen.dart';
import '../../tenants/tenants_screen.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  int _tabActual = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabActual == 0 ? 'Inicio' : 'Tenants',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_tabActual == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: () => context.read<TenantProvider>().cargarTodos(),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') _confirmarLogout(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabActual,
        children: [
          SuperAdminDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
          const TenantsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), label: 'Tenants'),
        ],
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
