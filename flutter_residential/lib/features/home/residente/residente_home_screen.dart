import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/residente/app_bar_residente.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../propiedades/screens/residente/mi_propiedad_screen.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import '../../inquilinos/screens/mis_inquilinos_screen.dart';
import '../../inquilinos/providers/inquilino_permisos_provider.dart';
import 'residente_dashboard_screen.dart';
import 'screens/perfil_residente_screen.dart';

class ResidenteHomeScreen extends StatefulWidget {
  const ResidenteHomeScreen({super.key});

  @override
  State<ResidenteHomeScreen> createState() => _ResidenteHomeScreenState();
}

class _ResidenteHomeScreenState extends State<ResidenteHomeScreen> {
  int _tabActual = 0;
  VoidCallback? _accionAgregarInquilino;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarMisPropiedades();

      // Limpiar permisos anteriores (por si cambia el usuario logueado)
      // y cargar los propios si es inquilino
      final auth = context.read<AuthProvider>();
      final permisosProvider = context.read<InquilinoPermisosProvider>();
      permisosProvider.limpiar();
      if (auth.isInquilino) {
        permisosProvider.cargar();
      }
    });
  }

  bool get _esPropietario => context.read<AuthProvider>().isPropietario;

  /// El inquilino puede ver Finanzas solo si tiene el permiso ESTADO_CUENTA
  bool get _tieneFinanzas {
    if (_esPropietario) return true;
    final permisos = context.read<InquilinoPermisosProvider>();
    return permisos.tienePermiso('ESTADO_CUENTA');
  }

  void _onTabSelected(int index) {
    // Mapear el índice de navegación considerando si Finanzas está o no
    if (_tieneFinanzas && index == 1) {
      // Finanzas → push
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
      );
      return;
    }

    // Si Finanzas está visible: los índices son 0=Inicio, 1=Finanzas(push), 2=Propiedad, 3=[Inquilinos|Perfil], 4=Perfil
    // Si Finanzas NO está visible: los índices son 0=Inicio, 1=Propiedad, 2=Perfil
    final stackIndex = _calcularStackIndex(index);
    setState(() => _tabActual = stackIndex);
  }

  int _calcularStackIndex(int navIndex) {
    if (_tieneFinanzas) {
      // nav: 0=Inicio, 1=Finanzas(push), 2=Propiedad, 3=[Inquilinos|Perfil], 4=Perfil
      if (navIndex == 0) return 0;
      if (navIndex >= 2) return navIndex - 1; // saltar el push de Finanzas
      return 0; // no debería ocurrir (1 ya fue manejado arriba)
    } else {
      // nav: 0=Inicio, 1=Propiedad, 2=Perfil
      return navIndex;
    }
  }

  int get _navIndex {
    if (_tieneFinanzas) {
      if (_tabActual == 0) return 0;           // Inicio
      if (_tabActual == 1) return 2;           // Propiedad
      if (_tabActual == 2) return _esPropietario ? 3 : 3; // Inquilinos o Perfil
      return 4;                                // Perfil (solo propietario)
    } else {
      // Sin Finanzas: stack y nav coinciden
      return _tabActual;
    }
  }

  List<Widget> get _stackScreens {
    if (_esPropietario) {
      return [
        ResidenteDashboardScreen(onNavegar: _onTabSelected),
        MisInquilinosScreen(
          onFabRegistrado: (accion) =>
              setState(() => _accionAgregarInquilino = accion),
        ),
        const PerfilResidenteScreen(),
      ];
    }
    return [
      ResidenteDashboardScreen(onNavegar: _onTabSelected),
      const PerfilResidenteScreen(),
    ];
  }

  List<NavigationDestination> get _destinations {
    final inicio = const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    );
    final finanzas = const NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Finanzas',
    );
    final inquilinos = const NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Inquilinos',
    );
    final perfil = const NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    );

    if (_esPropietario) {
      return [inicio, finanzas, inquilinos, perfil];
    }

    // Inquilino: Finanzas solo si tiene el permiso
    if (_tieneFinanzas) {
      return [inicio, finanzas, perfil];
    }
    return [inicio, perfil];
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de rol y permisos
    context.watch<AuthProvider>();
    context.watch<InquilinoPermisosProvider>();

    // FAB solo en el tab de Inquilinos (índice 2 del stack, solo propietario)
    final mostrarFabInquilinos =
        _esPropietario && _tabActual == 1;

    return Scaffold(
      appBar: AppBarResidente(),
      body: IndexedStack(
        index: _tabActual,
        children: _stackScreens,
      ),
      floatingActionButton: mostrarFabInquilinos
          ? FloatingActionButton.extended(
              onPressed: _accionAgregarInquilino,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Agregar inquilino'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
      ),
    );
  }
}
