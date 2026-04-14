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
      backgroundColor: Color.fromRGBO(244, 247, 249, 0.95),
      appBar: AppBar(
        title: Align(
          alignment: Alignment.topLeft,
          child: Row(
            children: [
              Container(
                width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(25, 53, 89, 1),
                    borderRadius: BorderRadius.circular(18), // rectangular con esquinas redondeadas
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _iniciales('Juan Perez'), // → "JP"
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ),
              const SizedBox(width: 12),
              Text(
                (auth.nombreConjunto ?? '').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: Color.fromRGBO(25, 53, 89, 1)
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.redAccent,
              ),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmarLogout(context),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            
          ),
          Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
        ],
        ),
      /*IndexedStack(
        index: _tabActual,
        children: [
          AdminDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
          const UsuariosScreen(),
          const _PlaceholderScreen(titulo: 'Propietarios'),
          const _PlaceholderScreen(titulo: 'Propiedades'),
        ],
      ),*/
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

String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
}