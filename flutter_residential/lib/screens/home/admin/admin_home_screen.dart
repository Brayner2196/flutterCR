import 'package:flutter/material.dart';
import 'package:flutter_residential/screens/home/admin/appBar/app_bar_admin.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../propiedades/propiedades_screen.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 247, 249, 0.95),
      appBar: AppBarAdmin(auth: auth, cs: cs),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Text(
                      'Hola, ${auth.nombre}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: cs.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
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
                    cs.surface.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) {
          setState(() => _tabActual = i);
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsuariosScreen()),
            ).then((_) {
              if (mounted) setState(() => _tabActual = 0);
            });
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PropiedadesScreen()),
            ).then((_) {
              if (mounted) setState(() => _tabActual = 0);
            });
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Usuarios'),
          NavigationDestination(icon: Icon(Icons.person_pin_outlined), label: 'Propietarios'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Propiedades'),
        ],
      ),
    );
  }

}
