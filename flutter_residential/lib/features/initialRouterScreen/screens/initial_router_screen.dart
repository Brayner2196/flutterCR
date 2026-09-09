import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../usuarios/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../home/super_admin/super_admin_home_screen.dart';
import '../../home/admin/admin_home_screen.dart';
import '../../home/contador/contador_home_screen.dart';
import '../../home/residente/residente_home_screen.dart';
import '../../vigilancia/screens/vigilante_home_screen.dart';
import '../../../shared/widgets/sesion_contexto_loader.dart';
import '../../../shared/widgets/sesion_lista_gate.dart';

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
          // El SUPER_ADMIN no pertenece a ningún conjunto: va sin loader ni
          // gate. Su token no lleva X-Tenant-ID, así que pedir los módulos
          // fallaría y el gate se quedaría esperando para siempre.
          if (auth.isSuperAdmin) return const SuperAdminHomeScreen();

          // Los demás roles van envueltos en dos capas con responsabilidades
          // separadas:
          //   SesionContextoLoader → dispara la carga de módulos y permisos
          //                          (y la recarga al cambiar de conjunto)
          //   SesionListaGate      → no construye la home hasta que ambos
          //                          respondan; mientras tanto, esqueleto
          if (auth.isAdmin) {
            return const _HomeConContexto(child: AdminHomeScreen());
          }
          if (auth.isAreaVigilancia) {
            return const _HomeConContexto(child: VigilanteHomeScreen());
          }
          // El contador tiene home propia: no ve usuarios ni propiedades, y sus
          // pestañas dependen de los permisos que el admin le haya dado.
          if (auth.isContador) {
            return const _HomeConContexto(child: ContadorHomeScreen());
          }
          // Los inquilinos ven la misma pantalla que los propietarios, solo que
          // con menos opciones.
          if (auth.isAreaResidente) {
            return const _HomeConContexto(child: ResidenteHomeScreen());
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

/// Loader + gate, que siempre van juntos y en este orden: primero se dispara la
/// carga del contexto, después se espera a que resuelva. Se extrae para no
/// repetir el anidamiento en cada rol y para que agregar una capa nueva sea un
/// cambio en un solo sitio.
class _HomeConContexto extends StatelessWidget {
  final Widget child;

  const _HomeConContexto({required this.child});

  @override
  Widget build(BuildContext context) {
    return SesionContextoLoader(child: SesionListaGate(child: child));
  }
}
