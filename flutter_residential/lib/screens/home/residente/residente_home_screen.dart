import 'package:flutter/material.dart';
import 'package:flutter_residential/models/usuario_propiedad_response.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/propiedad_provider.dart';
import 'residente_dashboard_screen.dart';

class ResidenteHomeScreen extends StatefulWidget {
  const ResidenteHomeScreen({super.key});

  @override
  State<ResidenteHomeScreen> createState() => _ResidenteHomeScreenState();
}

class _ResidenteHomeScreenState extends State<ResidenteHomeScreen> {
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.topLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container( // Avatar circular con iniciales
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _iniciales(auth.nombre ?? 'Usuario'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(84,121,224, 1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.nombreConjunto ?? 'Conjunto Residencial',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.5,
                          color: Color.fromRGBO(84,121,224, 1)
                        ),
                      ),
                      Skeletonizer(
                        enabled: propiedades.misPropiedades == null,
                         child: Text(
                           propiedades.propiedadActual?.pathTexto ?? '',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.black45,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                      ),
                    ],
                  )
            ],
          )
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
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
        bottom:  PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      /*body: IndexedStack(
        index: _tabActual,
        children: [
          ResidenteDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
          const MiPropiedadScreen(),
        ],
      ),*/
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - kToolbarHeight - 1, // Ajusta por AppBar y borde
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
          ),
          child: Column(
            children: [
              ResidenteDashboardScreen(onNavegar: (i) => setState(() => _tabActual = i)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Mi Propiedad'),
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

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  String? _propiedadText(UsuarioPropiedadResponse? propiedadActual){
    return propiedadActual?.pathTexto;
  }
}
