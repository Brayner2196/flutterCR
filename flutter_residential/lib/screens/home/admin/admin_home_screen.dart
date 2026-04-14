import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import '../../usuarios/usuarios_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabActual = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.nombreConjunto ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabActual,
        children: [
          AdminDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
          const UsuariosScreen(),
          const _PlaceholderScreen(titulo: 'Propietarios'),
          const _PlaceholderScreen(titulo: 'Propiedades'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Usuarios'),
          NavigationDestination(icon: Icon(Icons.person_pin_outlined), label: 'Propietarios'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Propiedades'),
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

class _PlaceholderScreen extends StatelessWidget {
  final String titulo;
  const _PlaceholderScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$titulo — próximo paso',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
