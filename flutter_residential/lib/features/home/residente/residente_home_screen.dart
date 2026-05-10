import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/residente/app_bar_residente.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../propiedades/screens/residente/mi_propiedad_screen.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import 'residente_dashboard_screen.dart';
import 'perfil_residente_screen.dart';

class ResidenteHomeScreen extends StatefulWidget {
  const ResidenteHomeScreen({super.key});

  @override
  State<ResidenteHomeScreen> createState() => _ResidenteHomeScreenState();
}

class _ResidenteHomeScreenState extends State<ResidenteHomeScreen> {
  /// 0=Inicio, 1=Finanzas(push), 2=Mi Propiedad, 3=Perfil
  /// Finanzas se navega por push y no vive en IndexedStack.
  int _tabActual = 0;

  AuthProvider get auth => context.watch<AuthProvider>();
  PropiedadProvider get propiedades => context.watch<PropiedadProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarMisPropiedades();
    });
  }

  void _onTabSelected(int index) {
    // Finanzas (tab 1) se abre como nueva pantalla para evitar Scaffold anidado
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
      );
      return;
    }

    // Mapear índices del nav a índices del IndexedStack (saltando tab 1)
    final stackIndex = index > 1 ? index - 1 : index;
    setState(() => _tabActual = stackIndex);
  }

  /// Convierte el índice del stack (0,1,2) al índice del nav (0,2,3)
  int get _navIndex {
    if (_tabActual == 0) return 0;       // Inicio
    if (_tabActual == 1) return 2;       // Mi Propiedad
    return 3;                             // Perfil
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBarResidente(),
      body: IndexedStack(
        index: _tabActual,
        children: [
          // Stack 0 — Inicio
          ResidenteDashboardScreen(
            onNavegar: (i) {
              // onNavegar recibe índices del nav (2 = Mi Propiedad)
              _onTabSelected(i);
            },
          ),
          // Stack 1 — Mi Propiedad
          const MiPropiedadScreen(),
          // Stack 2 — Perfil
          const PerfilResidenteScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded),
            label: 'Mi Propiedad',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

}
