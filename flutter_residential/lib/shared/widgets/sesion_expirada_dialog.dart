import 'dart:async';

import 'package:flutter/material.dart';

/// Modal de sesión expirada con cuenta regresiva. No se puede cerrar:
/// no tiene botones, tocar fuera no hace nada (barrierDismissible: false) y
/// el botón atrás está bloqueado (PopScope). Se cierra solo al llegar a cero.
///
/// Solo es UI: quien lo abre decide qué hacer al terminar (ver _SessionGuard).
class SesionExpiradaDialog extends StatefulWidget {
  final int segundos;

  const SesionExpiradaDialog({super.key, this.segundos = 5});

  /// Abre el modal y completa cuando termina la cuenta regresiva.
  static Future<void> mostrar(BuildContext context, {int segundos = 5}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => SesionExpiradaDialog(segundos: segundos),
    );
  }

  @override
  State<SesionExpiradaDialog> createState() => _SesionExpiradaDialogState();
}

class _SesionExpiradaDialogState extends State<SesionExpiradaDialog> {
  late int _restantes = widget.segundos;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restantes <= 1) {
        _timer?.cancel();
        // Navigator.pop no pasa por el PopScope: este solo bloquea el botón atrás.
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _restantes--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Tu sesión ha expirado',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Por seguridad debes iniciar sesión nuevamente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Anillo que se vacía de forma continua durante toda la cuenta,
            // con el número en el centro.
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 0),
                      duration: Duration(seconds: widget.segundos),
                      builder: (_, valor, __) => CircularProgressIndicator(
                        value: valor,
                        strokeWidth: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.error,
                      ),
                    ),
                  ),
                  Text(
                    '$_restantes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true, // los lectores de pantalla anuncian cada segundo
              child: Text(
                'Cerrando sesión en $_restantes…',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
