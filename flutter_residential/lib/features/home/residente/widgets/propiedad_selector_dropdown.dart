import 'package:flutter/material.dart';
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
                  _ScrollingText(
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

// ─── Widget de texto con scroll horizontal automático (marquee) ──────────────
//
// Si el texto cabe en el espacio disponible, se muestra estático.
// Si desborda, espera 1 s, hace scroll hasta el final al ritmo de 15 ms/px
// (aprox. 2-4 s dependiendo del largo), pausa 800 ms y vuelve al inicio.

class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _ScrollingText({required this.text, this.style});

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarScroll());
  }

  Future<void> _iniciarScroll() async {
    if (!mounted || !_controller.hasClients) return;
    final maxScroll = _controller.position.maxScrollExtent;
    if (maxScroll <= 0) return; // cabe completo — nada que hacer

    await _ciclo(maxScroll);
  }

  Future<void> _ciclo(double maxScroll) async {
    while (mounted) {
      // Pausa inicial para que el usuario lea el inicio
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // Desplaza hasta el final — 15 ms por px, acotado entre 1 s y 4 s
      final duracion = Duration(
        milliseconds: (maxScroll * 15).round().clamp(1000, 4000),
      );
      await _controller.animateTo(
        maxScroll,
        duration: duracion,
        curve: Curves.linear,
      );
      if (!mounted) return;

      // Pausa al final antes de reiniciar
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
