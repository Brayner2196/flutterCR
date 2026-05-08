import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../../screens/home/super_admin/super_admin_home_screen.dart';
import '../../../screens/home/admin/admin_home_screen.dart';
import '../../../screens/home/residente/residente_home_screen.dart';

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
          return const ResidenteHomeScreen();
        }

        if (app.haVistoOnboarding == false) {
          return const OnboardingScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
