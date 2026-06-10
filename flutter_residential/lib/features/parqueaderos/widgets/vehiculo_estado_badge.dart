import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/vehiculo_model.dart';

/// Badge de estado para un vehículo (Pendiente / Aprobado / Rechazado).
class VehiculoEstadoBadge extends StatelessWidget {
  final EstadoVehiculo estado;

  const VehiculoEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _colores(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color, String) _colores(EstadoVehiculo e) {
    switch (e) {
      case EstadoVehiculo.APROBADO:
        return (AppColors.bgGreen, AppColors.ok, 'Aprobado');
      case EstadoVehiculo.RECHAZADO:
        return (AppColors.dangerSoft, AppColors.danger, 'Rechazado');
      case EstadoVehiculo.PENDIENTE:
        return (AppColors.warningSoft, AppColors.warning, 'Pendiente');
    }
  }
}
