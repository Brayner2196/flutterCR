import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import '../usuarios/usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabActual = 0;

  void _cambiarTab(int index) {
    setState(() => _tabActual = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = _buildTabs(auth);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tabs[_tabActual].label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Info del conjunto
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
              if (value == 'logout') {
                _confirmarLogout(context);
              }
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
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: tabs.length > 1
          ? NavigationBar(
              selectedIndex: _tabActual,
              onDestinationSelected: _cambiarTab,
              destinations: tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icono),
                      label: t.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  List<_Tab> _buildTabs(AuthProvider auth) {
    final tabs = <_Tab>[
      _Tab(
        label: 'Inicio',
        icono: Icons.home_outlined,
        screen: DashboardScreen(onNavegar: _cambiarTab),
      ),
    ];

    if (auth.isSuperAdmin || auth.isAdmin) {
      tabs.add(
        _Tab(
          label: 'Usuarios',
          icono: Icons.people_outline,
          screen: const UsuariosScreen(),
        ),
      );
    }

    if (auth.isAdmin) {
      tabs.addAll([
        _Tab(
          label: 'Propietarios',
          icono: Icons.person_pin_outlined,
          screen: const _PlaceholderScreen(titulo: 'Propietarios'),
        ),
        _Tab(
          label: 'Propiedades',
          icono: Icons.home_work_outlined,
          screen: const _PlaceholderScreen(titulo: 'Propiedades'),
        ),
      ]);
    }

    return tabs;
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

class _Tab {
  final String label;
  final IconData icono;
  final Widget screen;
  _Tab({required this.label, required this.icono, required this.screen});
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
