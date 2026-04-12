import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'residente_dashboard_screen.dart';

class ResidenteHomeScreen extends StatefulWidget {
  const ResidenteHomeScreen({super.key});

  @override
  State<ResidenteHomeScreen> createState() => _ResidenteHomeScreenState();
}

class _ResidenteHomeScreenState extends State<ResidenteHomeScreen> {
  int _tabActual = 0;

  static const _titulos = ['Inicio', 'Mi Propiedad'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titulos[_tabActual],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (auth.nombreConjunto != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.nombreConjunto!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
          ResidenteDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
          const _PlaceholderScreen(titulo: 'Mi Propiedad'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Mi Propiedad'),
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
