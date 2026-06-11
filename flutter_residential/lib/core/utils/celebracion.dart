import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

/// Helper reutilizable para celebrar acciones exitosas (pago o abono confirmado).
///
/// Centraliza el uso de [flutter_confetti] para que cualquier pantalla lo
/// dispare con una sola línea: `Celebracion.confeti(context)`.
///
/// Requiere un [MaterialApp]/[Overlay] en la raíz (siempre presente en la app).
/// El overlay vive en el Navigator raíz, por lo que el efecto continúa aunque
/// la pantalla actual se cierre (pop) justo después de lanzarlo.
class Celebracion {
  Celebracion._();

  /// Lanza confeti desde la parte inferior-central hacia arriba.
  static void confeti(BuildContext context) {
    Confetti.launch(
      context,
      options: const ConfettiOptions(
        particleCount: 120,
        spread: 80,
        startVelocity: 42,
        y: 0.6,
      ),
    );
  }
}
