import 'package:flutter/material.dart';
import '../../screens/home/admin/widgets/dashboard/dashboard_tokens.dart';

/// Badge reutilizable que muestra el estado con colores codificados.
/// Funciona para reservas, PQRs y cualquier entidad con estado.
class EstadoBadge extends StatelessWidget {
  final String estado;
  final String label;

  const EstadoBadge({super.key, required this.estado, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colores(cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  (Color, Color) _colores(ColorScheme cs) {
    switch (estado) {
      case 'PENDIENTE':
        return (DashboardTokens.bgYellow, DashboardTokens.fgYellow);
      case 'APROBADA':
      case 'RESUELTO':
        return (DashboardTokens.bgGreen, DashboardTokens.fgGreen);
      case 'EN_PROCESO':
        return (DashboardTokens.bgOrange, DashboardTokens.fgOrange);
      case 'RECHAZADA':
      case 'CANCELADA':
      case 'CERRADO':
        return (DashboardTokens.bgRed, DashboardTokens.fgRed);
      default:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }
}
