import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Riel gris que contiene una fila de píldoras con scroll horizontal.
///
/// Extraído de `MesSelectorBar` (pestaña de Cobros) para que la barra de meses
/// de Cobranza se vea idéntica sin copiar el estilo: si el diseño cambia, se
/// cambia aquí y las dos barras siguen iguales.
class RielPildoras extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const RielPildoras({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }
}

/// Píldora de una barra de meses: etiqueta, icono opcional y contador opcional.
///
/// Presentacional pura — no sabe de períodos ni de cartera. La usan la barra de
/// Cobros (con el candado del período) y la de Cobranza (con el número de
/// morosos del mes).
class MesPildora extends StatelessWidget {
  final String label;
  final bool activo;
  final IconData? icono;

  /// Color del icono cuando la píldora NO está activa. Si es null, hereda el
  /// color del texto.
  final Color? colorIcono;

  /// Contador a la derecha de la etiqueta. Null = sin contador.
  final int? badge;

  final VoidCallback onTap;

  const MesPildora({
    super.key,
    required this.label,
    required this.activo,
    required this.onTap,
    this.icono,
    this.colorIcono,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorContenido = activo ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: activo ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Icon(
                    icono,
                    size: 14,
                    color: activo ? Colors.white : (colorIcono ?? colorContenido),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorContenido,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  _Contador(valor: badge!, activo: activo),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  final int valor;
  final bool activo;

  const _Contador({required this.valor, required this.activo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = activo
        ? Colors.white.withValues(alpha: 0.22)
        : cs.onSurfaceVariant.withValues(alpha: 0.12);
    final texto = activo ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$valor',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: texto),
      ),
    );
  }
}
