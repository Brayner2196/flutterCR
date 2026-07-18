import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/admin/app_bar_admin.dart';
import 'package:flutter_residential/features/home/admin/bottom_navigation_bar_admin.dart';
import 'package:flutter_residential/features/home/admin/screens/dashboard_admin_screen.dart';
import 'package:flutter_residential/features/home/admin/screens/perfil_admin_screen.dart';
import 'package:flutter_residential/features/usuarios/providers/usuario_provider.dart';
import 'package:flutter_residential/features/usuarios/screens/admin/usuarios_screen.dart';
import 'package:flutter_residential/features/usuarios/wizard/usuario_wizard_screen.dart';
import 'package:flutter_residential/features/propiedades/providers/propiedad_provider.dart';
import 'package:flutter_residential/features/propiedades/providers/gestion_propiedades_provider.dart';
import 'package:flutter_residential/features/propiedades/screens/admin/gestion_propiedades_screen.dart';
import 'package:flutter_residential/features/propiedades/widgets/crear_unidad_dialog.dart';
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
          GestionPropiedadesScreen(),
          PerfilAdminScreen(),
        ],
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: BottomNavigationBarAdmin(
        tabActual: _tabActual,
        onTabChanged: (i) => setState(() => _tabActual = i),
        colorScheme: cs,
      ),
    );
  }

  /// FAB contextual: crear usuario en la pestaña Usuarios, crear unidad en
  /// la pestaña Propiedades.
  Widget? _buildFab(BuildContext context) {
    if (_tabActual == 1) {
      return FloatingActionButton(
        onPressed: () async {
          final creado = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const UsuarioWizardScreen()),
          );
          if (creado == true && context.mounted) {
            context.read<UsuarioProvider>().cargarTodos();
          }
        },
        child: const Icon(Icons.add),
      );
    }
    if (_tabActual == 2) {
      return FloatingActionButton.extended(
        onPressed: _crearUnidad,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Crear unidad'),
      );
    }
    return null;
  }

  Future<void> _crearUnidad() async {
    final propProvider = context.read<PropiedadProvider>();
    if (propProvider.tiposArbol.isEmpty) {
      await propProvider.cargarTiposAdmin();
    }
    if (!mounted) return;
    final creada = await showDialog<bool>(
      context: context,
      builder: (_) =>
          CrearUnidadDialog(tiposRaiz: context.read<PropiedadProvider>().tiposArbol),
    );
    if (creada == true && mounted) {
      context.read<GestionPropiedadesProvider>().cargarTodas();
    }
  }
}