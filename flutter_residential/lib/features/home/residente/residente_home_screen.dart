import 'package:flutter/material.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _iniciales(auth.nombre ?? 'Usuario'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.nombreConjunto ?? 'Conjunto Residencial',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: cs.primary,
                  ),
                ),
                Skeletonizer(
                  enabled: propiedades.cargando,
                  child: Text(
                    propiedades.propiedadActual?.pathTexto ??
                        'Vivienda no seleccionada',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cs.outlineVariant),
        ),
      ),
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

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}
