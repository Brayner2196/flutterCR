import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/cobro_model.dart';
import '../utils/estado_cobro_ui.dart';
import 'cobro_estado_badge.dart';

/// Tarjeta reutilizable de un cobro (vista admin).
///
/// Reemplaza el `_CobroAdminTile` privado de `admin_cobros_screen`. Las
/// acciones se inyectan, así el mismo tile sirve en cobros, morosidad, etc.
class CobroTile extends StatelessWidget {
  final CobroModel cobro;

  /// Si se provee y el cobro es exonerable, muestra el botón "Exonerar".
  final void Function(CobroModel)? onExonerar;

  /// Acción al tocar la tarjeta (ver detalle / estado de cuenta).
  final VoidCallback? onTap;

  const CobroTile({
    super.key,
    required this.cobro,
    this.onExonerar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ui = EstadoCobroUi.de(cobro.estado);
    final puedeExonerar =
        onExonerar != null && (cobro.esPendiente || cobro.esVencido);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ui.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: ui.color.withValues(alpha: 0.12),
              child: Icon(Icons.home_work, color: ui.color, size: 20),
            ),
            title: Text(
              cobro.propiedadIdentificador,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            subtitle: Text(
              cobro.concepto,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.cop(cobro.montoTotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                CobroEstadoBadge(estado: cobro.estado, solido: true),
              ],
            ),
          ),
          if (puedeExonerar)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: ui.color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onExonerar!(cobro),
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: const Text('Exonerar', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
