import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../usuarios/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../home/super_admin/super_admin_home_screen.dart';
import '../../home/admin/admin_home_screen.dart';
import '../../home/residente/residente_home_screen.dart';
import '../../vigilancia/screens/vigilante_home_screen.dart';
import '../../modulos/widgets/modulos_loader.dart';

class InitialRouterScreen extends StatelessWidget {
  const InitialRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppProvider>(
      builder: (context, auth, app, _) {
        final cargandoSesion = auth.status == AuthStatus.inicial ||
            auth.status == AuthStatus.cargando;
        if (app.haVistoOnboarding == null || cargandoSesion) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isLoggedIn) {
          // El SUPER_ADMIN no pertenece a ningún conjunto: va sin ModulosLoader.
          if (auth.isSuperAdmin) return const SuperAdminHomeScreen();

          // Los demás roles sí: ModulosLoader carga (y recarga al cambiar de
          // conjunto) los módulos habilitados antes de que la home los use.
          if (auth.isAdmin) {
            return const ModulosLoader(child: AdminHomeScreen());
          }
          if (auth.isAreaVigilancia) {
            return const ModulosLoader(child: VigilanteHomeScreen());
          }
          // Los inquilinos ven la misma pantalla que los propietarios, solo que
          // con menos opciones.
          if (auth.isAreaResidente) {
            return const ModulosLoader(child: ResidenteHomeScreen());
          }
          // Fallback por si llega un rol desconocido
          return const LoginScreen();
        }

        if (app.haVistoOnboarding == false) {
          return const OnboardingScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
