import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/theme/app_theme.dart';

/// Tarjeta de recaudo del período: fondo azul de marca con anillo de
/// progreso (porcentaje recaudado), monto recaudado, esperado, faltante
/// y días para el cierre del período.
///
/// Reemplaza a `ResumenRecaudoHeader` en el hub de cobros (rediseño).
class RecaudoCard extends StatelessWidget {
  final double totalRecaudado;
  final double totalEsperado;

  /// Etiqueta del mes en curso, p. ej. "mayo".
  final String mesLabel;

  /// Días restantes para el cierre. `null` si no aplica o ya cerró.
  final int? diasCierre;

  /// Si el período está cerrado, se muestra "cerrado" en lugar de los días.
  final bool cerrado;

  const RecaudoCard({
    super.key,
    required this.totalRecaudado,
    required this.totalEsperado,
    required this.mesLabel,
    this.diasCierre,
    this.cerrado = false,
  });

  double get _pct =>
      totalEsperado > 0 ? (totalRecaudado / totalEsperado).clamp(0.0, 1.0) : 0.0;

  String get _subtitulo {
    final faltante = (totalEsperado - totalRecaudado).clamp(0, double.infinity);
    final partes = <String>['de ${CurrencyFormatter.cop(totalEsperado)}'];
    if (faltante > 0) {
      partes.add('faltan ${CurrencyFormatter.copCompacto(faltante)}');
    }
    if (cerrado) {
      partes.add('período cerrado');
    } else if (diasCierre != null) {
      partes.add(diasCierre! <= 0
          ? 'cierra hoy'
          : 'cierra en $diasCierre ${diasCierre == 1 ? 'día' : 'días'}');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    const blanco = Colors.white;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _Anillo(pct: _pct),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recaudado en $mesLabel',
                  style: TextStyle(
                    color: blanco.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.cop(totalRecaudado),
                    style: const TextStyle(
                      color: blanco,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitulo,
                  style: TextStyle(
                    color: blanco.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Anillo circular con el porcentaje al centro (blanco sobre azul).
class _Anillo extends StatelessWidget {
  final double pct;
  const _Anillo({required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: CustomPaint(
        painter: _AnilloPainter(pct: pct),
        child: Center(
          child: Text(
            '${(pct * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  final double pct;
  _AnilloPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeCap = StrokeCap.round;
    final progreso = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct.clamp(0.0, 1.0),
      false,
      progreso,
    );
  }

  @override
  bool shouldRepaint(_AnilloPainter old) => old.pct != pct;
}
