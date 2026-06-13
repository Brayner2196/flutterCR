import 'package:flutter/material.dart';
import '../models/estado_cartera_vigente_model.dart';
import '../utils/cartera_labels.dart';

/// Badge reutilizable que muestra el estado de cartera de una propiedad.
/// Si no hay estado, no renderiza nada (degradación segura).
class EstadoCarteraBadge extends StatelessWidget {
  final EstadoCarteraVigente? estado;
  final bool mostrarSiAlDia;

  const EstadoCarteraBadge({
    super.key,
    required this.estado,
    this.mostrarSiAlDia = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = estado;
    if (e == null || !e.tieneEstado) return const SizedBox.shrink();
    if (e.esPositivo && !mostrarSiAlDia) return const SizedBox.shrink();

    final color = CarteraLabels.colorDeHex(e.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            e.estadoNombre!,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
