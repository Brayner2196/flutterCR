import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/utils/scrollingText.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/features/propiedades/providers/propiedad_provider.dart';
import 'package:flutter_residential/features/home/residente/widgets/propiedad_chip.dart';
import 'package:flutter_residential/features/usuarios/models/usuario_propiedad_response.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Selector de propiedad del AppBar del residente.
///
/// - Sin propiedades asignadas: no se muestra nada.
/// - Con una sola propiedad: chip informativo, sin menú ni chevron.
/// - Con varias: menú desplegable para cambiar de propiedad.
///
/// El pathTexto del ítem hace scroll horizontal automático si no cabe completo.
class PropiedadSelectorDropdown extends StatelessWidget {
  final void Function(UsuarioPropiedadResponse propiedad) onPropiedadCambiada;

  const PropiedadSelectorDropdown({
    super.key,
    required this.onPropiedadCambiada,
  });

  @override
  Widget build(BuildContext context) {
    final propiedades = context.watch<PropiedadProvider>();
    final actual = propiedades.propiedadActual;
    final cs = Theme.of(context).colorScheme;

    // Sin propiedades asignadas: no hay contexto que mostrar.
    if (actual == null || propiedades.misPropiedades.isEmpty) {
      return const SizedBox.shrink();
    }

    // Una sola propiedad: mismo chip, informativo, sin menú ni chevron.
    if (!propiedades.tieneMultiplesPropiedades) {
      return Semantics(
        label: 'Propiedad: ${actual.pathTexto}',
        child: Tooltip(
          message: actual.pathTexto,
          child: PropiedadChip(
            etiqueta:
                actual.pathCorto.isNotEmpty ? actual.pathCorto : actual.pathTexto,
            esParqueadero: actual.esParqueadero,
            mostrarFlecha: false,
            maxAnchoTexto: 140,
          ),
        ),
      );
    }

    // Varias propiedades: menú para cambiar entre ellas.
    return PopupMenuButton<UsuarioPropiedadResponse>(
      tooltip: 'Cambiar propiedad',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      itemBuilder: (_) => propiedades.misPropiedades
          .map((p) => _buildMenuItem(context, p, actual, cs))
          .toList(),
      onSelected: (p) {
        if (p.propiedadId != actual.propiedadId) {
          context.read<PropiedadProvider>().seleccionarPropiedad(p);
          onPropiedadCambiada(p);
        }
      },
      child: PropiedadChip(
        etiqueta: actual.pathCorto,
        esParqueadero: actual.esParqueadero,
      ),
    );
  }

  // ─── Ítem del menú ───────────────────────────────────────────────────────

  PopupMenuEntry<UsuarioPropiedadResponse> _buildMenuItem(
    BuildContext context,
    UsuarioPropiedadResponse p,
    UsuarioPropiedadResponse? actual,
    ColorScheme cs,
  ) {
    final isSelected = p.propiedadId == actual?.propiedadId;
    return PopupMenuItem<UsuarioPropiedadResponse>(
      value: p,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: p.esParqueadero
                    ? AppColors.bgBlue
                    : cs.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                p.esParqueadero ? Icons.local_parking : Icons.home_outlined,
                size: 16,
                color: p.esParqueadero ? AppColors.blue : cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto con scroll horizontal automático si no cabe completo
                  ScrollingText(
                    text: p.pathTexto,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (p.esParqueadero)
                    Text(
                      'Parqueadero',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_rounded, size: 16, color: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}
