import 'package:flutter/material.dart';

/// Lo que ve un contador al que todavía no le asignaron permisos.
///
/// El rol por sí solo no habilita nada, así que este estado es normal justo
/// después del alta, no un error. El texto dice qué falta y quién lo resuelve,
/// para que el contador no reporte la app como rota.
class ContadorSinAlcance extends StatelessWidget {
  const ContadorSinAlcance({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
      ),
    );
  }
}
