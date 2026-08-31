import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vigilancia_provider.dart';
import '../../modulos/providers/modulos_provider.dart';
import '../../../core/enums/modulo.dart';
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
      // Sin el módulo de vigilancia el backend responde 403: no se pide.
      if (context.read<ModulosProvider>().activo(Modulo.vigilancia)) {
        context.read<VigilanciaProvider>().cargarResumen();
      }
    });
  }

  void _onTabSelected(int index) => setState(() => _tabActual = index);

  /// Portería operativa: si el conjunto no tiene el módulo de vigilancia,
  /// Acceso y Bitácora no tienen razón de existir (el backend las rechaza).
  bool get _verOperacion =>
      context.read<ModulosProvider>().activo(Modulo.vigilancia);

  /// La paquetería es un módulo aparte que depende de vigilancia.
  bool get _verPaquetes =>
      context.read<ModulosProvider>().activo(Modulo.paquetes);

  List<Widget> get _stackScreens => [
        VigilanteDashboardScreen(onNavegar: _onTabSelected),
        if (_verOperacion) const AccesoScreen(),
        if (_verPaquetes) const PaquetesVigilanteScreen(),
        if (_verOperacion) const BitacoraScreen(),
        const PerfilVigilanteScreen(),
      ];

  /// Destinos 1:1 con [_stackScreens]. Se construyen juntos a propósito: si
  /// las dos listas se desalinean, el usuario toca "Perfil" y aterriza en otra
  /// pantalla.
  List<NavigationDestination> get _destinations => [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        if (_verOperacion)
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Acceso',
          ),
        if (_verPaquetes)
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Paquetes',
          ),
        if (_verOperacion)
          const NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Bitácora',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    context.watch<ModulosProvider>();

    final pantallas = _stackScreens;
    // Si un módulo se apaga mientras el vigilante está parado en esa pestaña,
    // el índice guardado apunta fuera de la lista: se acota para no reventar
    // el IndexedStack.
    final indice = _tabActual.clamp(0, pantallas.length - 1);

    return Scaffold(
      appBar: const AppBarVigilante(),
      body: IndexedStack(index: indice, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
      ),
    );
  }
}
