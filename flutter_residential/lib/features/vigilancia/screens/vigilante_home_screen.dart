import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vigilancia_provider.dart';
import 'app_bar_vigilante.dart';
import 'vigilante_dashboard_screen.dart';
import 'acceso_screen.dart';
import 'paquetes_vigilante_screen.dart';
import 'bitacora_screen.dart';
import 'perfil_vigilante_screen.dart';

/// Home del rol VIGILANTE. Misma estructura (Scaffold + IndexedStack +
/// NavigationBar) que el home del propietario, para mantener consistencia visual.
class VigilanteHomeScreen extends StatefulWidget {
  const VigilanteHomeScreen({super.key});

  @override
  State<VigilanteHomeScreen> createState() => _VigilanteHomeScreenState();
}

class _VigilanteHomeScreenState extends State<VigilanteHomeScreen> {
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<VigilanciaProvider>();
      prov.cargarPropiedades();
      prov.cargarResumen();
    });
  }

  void _onTabSelected(int index) => setState(() => _tabActual = index);

  List<Widget> get _stackScreens => [
        VigilanteDashboardScreen(onNavegar: _onTabSelected),
        const AccesoScreen(),
        const PaquetesVigilanteScreen(),
        const BitacoraScreen(),
        const PerfilVigilanteScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarVigilante(),
      body: IndexedStack(index: _tabActual, children: _stackScreens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Acceso',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Paquetes',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Bitácora',
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
