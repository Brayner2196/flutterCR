import 'package:flutter/material.dart';
import 'package:flutter_residential/providers/app_provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'features/auth/providers/auth_provider.dart';
import 'providers/cobros_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'providers/pagos_provider.dart';
import 'providers/pqr_provider.dart';
import 'providers/propiedad_provider.dart';
import 'providers/reserva_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/abono_provider.dart';
import 'providers/residente_estadisticas_provider.dart';
import 'providers/tenant_provider.dart';
import 'features/anuncios/providers/anuncio_provider.dart';
import 'providers/votacion_provider.dart';
import 'features/initialRouterScreen/screens/initial_router_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ],
      child: ToastificationWrapper(
        child: Consumer<AppProvider>(
          builder: (_, AppProvider appProvider, __) {
            return MaterialApp(
              title: 'Conjunto Residencial',
              debugShowCheckedModeBanner: false,
              themeMode: appProvider.themeMode,
              theme: buildAppTheme(brightness: Brightness.light),
              darkTheme: buildAppTheme(brightness: Brightness.dark),
              home: const InitialRouterScreen(),
            );
          },
        ),
      ),
    );
  }
}
