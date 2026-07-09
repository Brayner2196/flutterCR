import 'package:flutter/material.dart';
import 'package:flutter_residential/features/configuracion/screens/configuracion_screen.dart';
import 'package:flutter_residential/features/home/admin/app_bar_admin.dart';
import 'package:flutter_residential/features/home/admin/bottom_navigation_bar_admin.dart';
import 'package:flutter_residential/features/home/admin/screens/dashboard_admin_screen.dart';
import 'package:flutter_residential/features/home/admin/screens/perfil_admin_screen.dart';
import 'package:flutter_residential/features/usuarios/providers/usuario_provider.dart';
import 'package:flutter_residential/features/usuarios/screens/admin/usuarios_screen.dart';
import 'package:flutter_residential/features/usuarios/wizard/usuario_wizard_screen.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

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
      // Mismo fondo que el home del rol propietario: hereda scaffoldBackgroundColor
      // del tema (bgLight/bgDark) en lugar de cs.surface, para unificar el estilo.
      appBar: AppBarAdmin(auth: auth, cs: cs, habilitarlogout: true, habilitarReturnScreen: true,),
      body: IndexedStack(
        index: _tabActual,
        children: const [
          DashboardAdminScreen(),
          UsuariosScreen(),
          ConfiguracionScreen(),
          PerfilAdminScreen(),
        ],
      ),
      floatingActionButton: _tabActual == 1
          ? FloatingActionButton(
              onPressed: () async {
                final creado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const UsuarioWizardScreen(),
                  ),
                );
                if (creado == true && context.mounted) {
                  context.read<UsuarioProvider>().cargarTodos();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBarAdmin(
        tabActual: _tabActual,
        onTabChanged: (i) => setState(() => _tabActual = i),
        colorScheme: cs,
      ),
    );
  }
}
