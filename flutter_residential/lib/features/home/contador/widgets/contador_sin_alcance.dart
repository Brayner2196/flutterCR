import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/dialogs/confirmar_logout.dart';
import '../../../auth/providers/auth_provider.dart';

/// Lo que ve un contador al que todavía no le asignaron permisos.
///
/// El rol por sí solo no habilita nada, así que este estado es normal justo
/// después del alta, no un error. El texto dice qué falta y quién lo resuelve,
/// para que el contador no reporte la app como rota.
///
/// ## Por qué lleva su propio botón de salir
///
/// Sin permisos no hay ninguna pestaña que mostrar, ni siquiera Perfil, que es
/// donde los demás roles cierran sesión. Y `AppBarAdmin` recibe un
/// `habilitarlogout` que nunca usa en su cuerpo, así que tampoco aporta salida.
/// Sin este botón el contador queda encerrado en la pantalla y la única forma
/// de salir es desinstalar la app o borrar sus datos.
class ContadorSinAlcance extends StatelessWidget {
  const ContadorSinAlcance({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_outlined, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu acceso está por configurarse',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tu cuenta de contador ya está creada, pero el administrador '
              'del conjunto todavía no te asignó permisos.\n\n'
              'Pídele que los active desde Usuarios › tu perfil › Permisos contables.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => LogoutDialog.confirmar(
                context,
                context.read<AuthProvider>(),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
