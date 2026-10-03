import 'package:flutter/material.dart';

/// Aviso en línea: ícono + texto sobre un fondo suave del mismo tono.
///
/// Para advertencias o información dentro de una tarjeta o formulario, donde
/// un toast se perdería (ej.: "la deuda cambió desde la solicitud").
class AvisoCard extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;
  final IconData icono;

  const AvisoCard({
    super.key,
    required this.texto,
    required this.color,
    required this.fondo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
