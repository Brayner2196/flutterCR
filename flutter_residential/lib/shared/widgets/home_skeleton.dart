import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_theme.dart';

/// Esqueleto del shell de la home mientras se resuelve el contexto de sesión.
///
/// Reproduce la silueta común a las tres homes (AppBar + bloque destacado +
/// grilla de accesos + barra inferior), no el contenido de ninguna en concreto:
/// a esta altura todavía no se sabe qué módulos hay, y ese es justamente el
/// punto.
///
/// Se prefiere sobre un `CircularProgressIndicator` a pantalla completa porque
/// un spinner justo después del login se lee como "se trabó otra vez", mientras
/// que un esqueleto que se convierte en la pantalla real se lee como
/// instantáneo. Usa `Skeletonizer`, que ya es el lenguaje de carga del proyecto
/// (dashboard del residente, KPIs del admin, cobros).
///
/// El número de accesos (6) y de pestañas (4) es deliberadamente el del caso
/// típico: si el conjunto tiene más o menos, la diferencia se nota mucho menos
/// que la ausencia total de silueta.
class HomeSkeleton extends StatelessWidget {
  /// Cuántas tarjetas de acceso rápido dibujar.
  final int accesos;

  /// Cuántas pestañas dibujar en la barra inferior.
  final int pestanas;

  const HomeSkeleton({super.key, this.accesos = 6, this.pestanas = 4});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Skeletonizer(
          child: Container(
            height: 18,
            width: 160,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
      body: Skeletonizer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloque destacado: el resumen de deuda del residente / el
              // carrusel de KPIs del admin ocupan este mismo lugar.
              _Bloque(alto: 120, radio: AppRadius.lg, color: cs.surfaceContainerHighest),
              const SizedBox(height: AppSpacing.lg),
              _Bloque(alto: 12, ancho: 120, radio: AppRadius.sm, color: cs.surfaceContainerHighest),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.30,
                ),
                itemCount: accesos,
                itemBuilder: (_, _) => _Bloque(
                  radio: AppRadius.lg,
                  color: cs.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Skeletonizer(
        child: NavigationBar(
          selectedIndex: 0,
          destinations: List.generate(
            pestanas,
            (_) => const NavigationDestination(
              icon: Icon(Icons.circle_outlined),
              label: '     ',
            ),
          ),
        ),
      ),
    );
  }
}

/// Rectángulo neutro. Existe para no repetir el mismo `Container` decorado
/// cinco veces en este archivo.
class _Bloque extends StatelessWidget {
  final double? alto;
  final double? ancho;
  final double radio;
  final Color color;

  const _Bloque({this.alto, this.ancho, required this.radio, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      width: ancho,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
  }
}
