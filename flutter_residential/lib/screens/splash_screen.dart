import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'login/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/super_admin/super_admin_home_screen.dart';
import 'home/admin/admin_home_screen.dart';
import 'home/residente/residente_home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
