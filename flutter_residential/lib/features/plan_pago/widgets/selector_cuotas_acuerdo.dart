import 'package:flutter/material.dart';

/// Selector del número de cuotas diferidas.
///
/// Presentacional puro: no sabe de acuerdos ni de montos, solo emite el número
/// elegido. Lo usan la pantalla de solicitud y cualquier simulador futuro.
class SelectorCuotasAcuerdo extends StatelessWidget {
  final int maxCuotas;
  final int cuotas;
  final ValueChanged<int> onChanged;
  final bool habilitado;

  const SelectorCuotasAcuerdo({
    super.key,
    required this.maxCuotas,
    required this.cuotas,
    required this.onChanged,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (maxCuotas <= 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(maxCuotas, (i) {
        final n = i + 1;
        final activo = cuotas == n;
        return GestureDetector(
          onTap: habilitado ? () => onChanged(n) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: activo ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activo ? cs.primary : cs.outline,
                width: activo ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: activo ? Colors.white : cs.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
