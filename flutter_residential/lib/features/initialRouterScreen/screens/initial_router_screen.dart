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
          if (auth.isSuperAdmin) return const SuperAdminHomeScreen();
          if (auth.isAdmin) return const AdminHomeScreen();
          if (auth.isAreaVigilancia) return const VigilanteHomeScreen();
          if (auth.isAreaResidente) return const ResidenteHomeScreen();// Los inquilinos ven la misma pantalla que los propietarios, solo que con menos opciones
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
