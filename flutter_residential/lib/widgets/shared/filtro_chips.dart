import 'package:flutter/material.dart';

/// Modelo de cada opción del filtro.
class FiltroOption {
  final String label;
  final String? valor;

  const FiltroOption({required this.label, this.valor});
}

/// Barra horizontal de chips de filtro reutilizable.
class FiltroChips extends StatelessWidget {
  final List<FiltroOption> opciones;
  final String? valorActual;
  final ValueChanged<String?> onSeleccionar;

  const FiltroChips({
    super.key,
    required this.opciones,
    required this.valorActual,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: opciones
              .map((op) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Chip(
                      label: op.label,
                      activo: valorActual == op.valor,
                      onTap: () => onSeleccionar(op.valor),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? cs.primary : cs.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
