import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_residential/core/services/notificacion_service.dart';
import 'package:flutter_residential/features/usuarios/providers/app_provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/pagos/providers/cobros_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/pagos/providers/pagos_provider.dart';
import 'features/pqr/providers/pqr_provider.dart';
import 'features/propiedades/providers/propiedad_provider.dart';
import 'features/reservas/providers/reserva_provider.dart';
import 'features/usuarios/providers/usuario_provider.dart';
import 'features/pagos/providers/abono_provider.dart';
import 'features/usuarios/providers/residente_estadisticas_provider.dart';
import 'features/tenants/providers/tenant_provider.dart';
import 'features/anuncios/providers/anuncio_provider.dart';
import 'features/votaciones/providers/votacion_provider.dart';
import 'features/marketplace/providers/publicacion_provider.dart';
import 'features/inquilinos/providers/inquilino_permisos_provider.dart';
import 'core/network/api_client.dart';
import 'core/providers/connectivity_provider.dart';
import 'shared/widgets/offline_banner.dart';
import 'features/initialRouterScreen/screens/initial_router_screen.dart';

/// Escucha el stream de sesión expirada del ApiClient y llama a AuthProvider.sesionExpirada().
/// No necesita NavigatorKey porque InitialRouterScreen ya reacciona al status de AuthProvider.
class _SessionGuard extends StatefulWidget {
  final Widget child;
  const _SessionGuard({required this.child});

  @override
  State<_SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<_SessionGuard> {
  late final _sub = ApiClient.sessionExpiredStream.listen((_) {
    if (mounted) {
      context.read<AuthProvider>().sesionExpirada();
    }
  });

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// NavigatorKey global — permite que NotificacionService navegue sin BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificacionService().configurarNavigator(navigatorKey);
  await NotificacionService().inicializar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarSesionGuardada()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => PropiedadProvider()),
        ChangeNotifierProvider(create: (_) => CobrosProvider()),
        ChangeNotifierProvider(create: (_) => PagosProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PqrProvider()),
        ChangeNotifierProvider(create: (_) => ReservaProvider()),
        ChangeNotifierProvider(create: (_) => ResidenteEstadisticasProvider()),
        ChangeNotifierProvider(create: (_) => AbonoProvider()),
        ChangeNotifierProvider(create: (_) => AnuncioProvider()),
        ChangeNotifierProvider(create: (_) => VotacionProvider()),
        ChangeNotifierProvider(create: (_) => PublicacionProvider()),
        ChangeNotifierProvider(create: (_) => InquilinoPermisosProvider()),
      ],
      child: ToastificationWrapper(
        child: Consumer<AppProvider>(
          builder: (_, AppProvider appProvider, __) {
            return MaterialApp(
              title: 'Conjunto Residencial',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              themeMode: appProvider.themeMode,
              theme: buildAppTheme(brightness: Brightness.light),
              darkTheme: buildAppTheme(brightness: Brightness.dark),
              home: const _SessionGuard(
                child: OfflineGuard(child: InitialRouterScreen()),
              ),
            );
          },
        ),
      ),
    );
  }
}
