import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/residente/app_bar_residente.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import '../../inquilinos/screens/mis_inquilinos_screen.dart';
import '../../inquilinos/providers/inquilino_permisos_provider.dart';
import '../../usuarios/models/usuario_propiedad_response.dart';
import '../../usuarios/providers/residente_estadisticas_provider.dart';
import '../../anuncios/providers/anuncio_provider.dart';
import '../../pqr/providers/pqr_provider.dart';
import '../../votaciones/providers/votacion_provider.dart';
import 'residente_dashboard_screen.dart';
import 'screens/perfil_residente_screen.dart';
import '../../consejo/screens/consejo_dashboard_screen.dart';

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

      // Limpiar permisos anteriores y cargar los propios si es inquilino
      final auth = context.read<AuthProvider>();
      final permisosProvider = context.read<InquilinoPermisosProvider>();
      permisosProvider.limpiarDatos();
      if (auth.isInquilino) {
        permisosProvider.cargar();
      }
    });
  }

  bool get _esPropietario => context.read<AuthProvider>().isPropietario;
  bool get _esConsejero => context.read<AuthProvider>().esConsejero;

  /// El inquilino puede ver Finanzas solo si tiene el permiso ESTADO_CUENTA
  bool get _tieneFinanzas {
    if (_esPropietario) return true;
    final permisos = context.read<InquilinoPermisosProvider>();
    return permisos.tienePermiso('ESTADO_CUENTA');
  }

  /// Llamado desde el AppBar al cambiar de propiedad.
  /// Recarga todos los providers que dependen de la propiedad activa.
  void _onPropiedadCambiada(UsuarioPropiedadResponse propiedad) {
    final auth = context.read<AuthProvider>();
    final permisos = context.read<InquilinoPermisosProvider>();
    final esPropietario = auth.isPropietario;
    final esParqueadero = propiedad.esParqueadero;

    // Estadísticas / estado de cuenta — filtradas por la propiedad seleccionada
    if (esPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
      context.read<ResidenteEstadisticasProvider>()
          .cargar(propiedadId: propiedad.propiedadId);
    }

    // Anuncios (permitidos siempre para parqueaderos)
    if (esPropietario || permisos.tienePermiso('ANUNCIOS')) {
      context.read<AnuncioProvider>().cargarResidente();
    }

    // PQRs (permitidos para parqueaderos)
    if (esPropietario || permisos.tienePermiso('PQRS')) {
      context.read<PqrProvider>().cargarMisPqrs();
    }

    // Votaciones — bloqueadas para parqueaderos
    if (!esParqueadero && (esPropietario || permisos.tienePermiso('VOTAR'))) {
      context.read<VotacionProvider>().cargarResidente();
    }

    // Volver a la pestaña de inicio al cambiar propiedad
    if (_tabActual != 0) setState(() => _tabActual = 0);
  }

  void _onTabSelected(int index) {
    setState(() => _tabActual = index);
  }

  /// El stack index coincide directamente con el nav index:
  /// Propietario:                   [Inicio(0), Finanzas(1), Inquilinos(2), Perfil(3)]
  /// Propietario + Consejero:       [Inicio(0), Finanzas(1), Inquilinos(2), Consejo(3), Perfil(4)]
  /// Inquilino con finanzas:        [Inicio(0), Finanzas(1), Perfil(2)]
  /// Inquilino con finanzas+Cns:    [Inicio(0), Finanzas(1), Consejo(2), Perfil(3)]
  /// Inquilino sin finanzas:        [Inicio(0), Perfil(1)]
  /// Inquilino sin finanzas+Cns:    [Inicio(0), Consejo(1), Perfil(2)]
  List<Widget> get _stackScreens {
    if (_esPropietario) {
      return [
        ResidenteDashboardScreen(onNavegar: _onTabSelected),
        const EstadoCuentaScreen(),
        MisInquilinosScreen(
          onFabRegistrado: (accion) =>
              setState(() => _accionAgregarInquilino = accion),
        ),
        if (_esConsejero) const ConsejoDashboardScreen(),
        const PerfilResidenteScreen(),
      ];
    }
    if (_tieneFinanzas) {
      return [
        ResidenteDashboardScreen(onNavegar: _onTabSelected),
        const EstadoCuentaScreen(),
        if (_esConsejero) const ConsejoDashboardScreen(),
        const PerfilResidenteScreen(),
      ];
    }
    return [
      ResidenteDashboardScreen(onNavegar: _onTabSelected),
      if (_esConsejero) const ConsejoDashboardScreen(),
      const PerfilResidenteScreen(),
    ];
  }

  List<NavigationDestination> get _destinations {
    const inicio = NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    );
    const finanzas = NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Finanzas',
    );
    const inquilinos = NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Inquilinos',
    );
    const perfil = NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    );
    const consejo = NavigationDestination(
      icon: Icon(Icons.gavel_outlined),
      selectedIcon: Icon(Icons.gavel_rounded),
      label: 'Consejo',
    );

    if (_esPropietario) {
      return [inicio, finanzas, inquilinos, if (_esConsejero) consejo, perfil];
    }

    if (_tieneFinanzas) {
      return [inicio, finanzas, if (_esConsejero) consejo, perfil];
    }
    return [inicio, if (_esConsejero) consejo, perfil];
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    context.watch<InquilinoPermisosProvider>();

    // Inquilinos siempre en índice 2 para propietario (Finanzas ocupa el índice 1)
    final mostrarFabInquilinos = _esPropietario && _tabActual == 2;

    return Scaffold(
      appBar: AppBarResidente(onPropiedadCambiada: _onPropiedadCambiada),
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
        selectedIndex: _tabActual,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
      ),
    );
  }
}
