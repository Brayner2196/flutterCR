import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login/login_screen.dart';
import 'home/super_admin/super_admin_home_screen.dart';
import 'home/admin/admin_home_screen.dart';
import 'home/residente/residente_home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.inicial || auth.status == AuthStatus.cargando) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isLoggedIn) {
          if (auth.isSuperAdmin) return const SuperAdminHomeScreen();
          if (auth.isAdmin) return const AdminHomeScreen();
          return const ResidenteHomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}