import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/utils/scrollingText.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/features/propiedades/providers/propiedad_provider.dart';
import 'package:flutter_residential/features/usuarios/models/usuario_propiedad_response.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Dropdown compacto en el AppBar para cambiar entre propiedades del residente.
/// Solo se muestra cuando el usuario tiene más de una propiedad asignada.
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

    if (!propiedades.tieneMultiplesPropiedades) return const SizedBox.shrink();

    final actual = propiedades.propiedadActual;
    final cs = Theme.of(context).colorScheme;

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
        if (p.propiedadId != actual?.propiedadId) {
          context.read<PropiedadProvider>().seleccionarPropiedad(p);
          onPropiedadCambiada(p);
        }
      },
      child: _buildTrigger(context, actual, cs),
    );
  }

  // ─── Trigger visible en el AppBar ────────────────────────────────────────

  Widget _buildTrigger(
    BuildContext context,
    UsuarioPropiedadResponse? actual,
    ColorScheme cs,
  ) {
    final esParqueadero = actual?.esParqueadero ?? false;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esParqueadero ? Icons.local_parking : Icons.home_outlined,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              actual?.pathCorto ?? '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Icon(Icons.expand_more_rounded, size: 16, color: cs.primary),
        ],
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