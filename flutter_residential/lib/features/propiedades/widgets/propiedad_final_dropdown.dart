import 'package:flutter/material.dart';
import '../../../shared/widgets/buscador_dropdown.dart';
import '../models/propiedad_admin.dart';

/// Selector de una propiedad FINAL (hoja del arbol) con buscador por path corto.
///
/// Solo ofrece unidades que ya existen y que no tienen unidades por debajo: es
/// imposible armar con el una propiedad inexistente o apuntar a un nodo
/// intermedio (una Torre, un Piso).
///
/// Reutilizable en cualquier flujo que deba apuntar a una unidad ya registrada
/// (cobro especial, asignaciones, reportes).
class PropiedadFinalDropdown extends StatelessWidget {
  /// Propiedades tal como llegan del backend (todos los nodos del arbol).
  /// El filtrado a hojas lo hace este widget.
  final List<PropiedadAdmin> propiedades;

  final PropiedadAdmin? seleccionada;
  final ValueChanged<PropiedadAdmin?> onChanged;

  /// Restringe a unidades facturables. Por defecto false: hay operaciones que
  /// aplican igual sobre unidades no facturables.
  final bool soloFacturables;

  final String label;
  final String hintText;
  final String? errorText;
  final bool enabled;

  const PropiedadFinalDropdown({
    super.key,
    required this.propiedades,
    required this.onChanged,
    this.seleccionada,
    this.soloFacturables = false,
    this.label = 'Propiedad',
    this.hintText = 'Escribe A101, 101, torre A...',
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = propiedades.finales(soloFacturables: soloFacturables);

    return BuscadorDropdown<PropiedadAdmin>(
      items: items,
      seleccionado: seleccionada,
      onChanged: onChanged,
      label: label,
      hintText: hintText,
      errorText: errorText,
      enabled: enabled,
      icon: Icons.home_work_outlined,
      mensajeVacio: soloFacturables
          ? 'No hay unidades facturables registradas'
          : 'No hay unidades registradas',
      // Path corto ("A101"); cae al path completo si el conjunto no lo tiene.
      etiqueta: (p) => p.titulo,
      // Path completo ("Torre A / Piso 1 / Apartamento 101"), salvo que ya sea
      // lo que se muestra arriba.
      descripcion: (p) => p.pathTexto == p.titulo ? '' : p.pathTexto,
      sufijo: (p) =>
          p.esFacturable ? null : const _BadgeNoFacturable(),
    );
  }
}

/// Advertencia visual: la unidad existe pero no factura.
class _BadgeNoFacturable extends StatelessWidget {
  const _BadgeNoFacturable();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'no factura',
        style: TextStyle(fontSize: 10, color: cs.onTertiaryContainer),
      ),
    );
  }
}
