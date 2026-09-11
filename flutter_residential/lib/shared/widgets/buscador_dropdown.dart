import 'package:flutter/material.dart';
import '../../core/utils/texto_utils.dart';
import '../theme/app_theme.dart';

/// Dropdown con buscador sobre una lista YA cargada en memoria.
///
/// Es presentacional y genérico a propósito: no sabe de dominio ni hace
/// peticiones. Quien lo usa decide qué son los items, cómo se etiquetan y de
/// dónde salen. Reutilizable en cualquier selección "elige uno de estos".
///
/// Reglas que garantiza:
///   - Solo se puede elegir un item de [items]; nunca un valor libre.
///   - Si el usuario escribe y sale sin elegir, el texto vuelve al seleccionado.
///   - La búsqueda ignora tildes, mayúsculas y separadores
///     (ver [TextoUtils.normalizarBusqueda]).
class BuscadorDropdown<T> extends StatefulWidget {
  /// Opciones disponibles. Ya filtradas/ordenadas por quien lo usa.
  final List<T> items;

  final T? seleccionado;

  /// Texto principal del item y del campo una vez elegido (ej. el path corto).
  final String Function(T) etiqueta;

  /// Texto secundario bajo la etiqueta (ej. el path completo). También se
  /// incluye en la búsqueda.
  final String Function(T)? descripcion;

  /// Widget opcional al final de cada opción (ej. un badge de advertencia).
  final Widget? Function(T)? sufijo;

  final ValueChanged<T?> onChanged;

  final String label;
  final String hintText;
  final IconData icon;
  final Color? color;
  final bool enabled;

  /// Mensaje cuando [items] está vacío.
  final String mensajeVacio;

  /// Error a mostrar bajo el campo (lo controla el formulario de afuera).
  final String? errorText;

  const BuscadorDropdown({
    super.key,
    required this.items,
    required this.etiqueta,
    required this.onChanged,
    required this.label,
    this.seleccionado,
    this.descripcion,
    this.sufijo,
    this.hintText = 'Escribe para buscar...',
    this.icon = Icons.search_rounded,
    this.color,
    this.enabled = true,
    this.mensajeVacio = 'Sin opciones disponibles',
    this.errorText,
  });

  @override
  State<BuscadorDropdown<T>> createState() => _BuscadorDropdownState<T>();
}

class _BuscadorDropdownState<T> extends State<BuscadorDropdown<T>> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _sincronizarTexto();
    // Al perder el foco sin haber elegido, el texto escrito se descarta: el
    // campo siempre refleja un item real (o vacío).
    _focus.addListener(() {
      if (!_focus.hasFocus) _sincronizarTexto();
    });
  }

  @override
  void didUpdateWidget(covariant BuscadorDropdown<T> old) {
    super.didUpdateWidget(old);
    if (old.seleccionado != widget.seleccionado) _sincronizarTexto();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sincronizarTexto() {
    final sel = widget.seleccionado;
    final txt = sel == null ? '' : widget.etiqueta(sel);
    if (_ctrl.text != txt) _ctrl.text = txt;
  }

  /// Filtra por etiqueta + descripción, ambas normalizadas.
  List<DropdownMenuEntry<T>> _filtrar(
      List<DropdownMenuEntry<T>> entries, String filtro) {
    final q = TextoUtils.normalizarBusqueda(filtro);
    if (q.isEmpty) return entries;
    return entries.where((e) {
      final item = e.value;
      final base =
          '${widget.etiqueta(item)} ${widget.descripcion?.call(item) ?? ''}';
      return TextoUtils.normalizarBusqueda(base).contains(q);
    }).toList();
  }

  DropdownMenuEntry<T> _entry(T item, ColorScheme cs) {
    final desc = widget.descripcion?.call(item);
    return DropdownMenuEntry<T>(
      value: item,
      // `label` es lo que el DropdownMenu escribe en el campo al elegir.
      label: widget.etiqueta(item),
      trailingIcon: widget.sufijo?.call(item),
      style: MenuItemButton.styleFrom(
        // Sin altura explícita, la opción de dos líneas desborda.
        minimumSize: Size.fromHeight(desc == null || desc.isEmpty ? 44 : 58),
        alignment: Alignment.centerLeft,
      ),
      labelWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.etiqueta(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (desc != null && desc.isNotEmpty)
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary;

    if (widget.items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: color),
          errorText: widget.errorText,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.mensajeVacio,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownMenu<T>(
      controller: _ctrl,
      focusNode: _focus,
      enabled: widget.enabled,
      expandedInsets: EdgeInsets.zero,
      // Siempre activos: permiten volver a buscar sin tener que borrar a mano.
      enableFilter: true,
      requestFocusOnTap: true,
      filterCallback: _filtrar,
      initialSelection: widget.seleccionado,
      label: Text(widget.label),
      hintText: widget.hintText,
      leadingIcon: Icon(widget.icon, color: color),
      menuHeight: 320,
      errorText: widget.errorText,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dropdownMenuEntries: widget.items.map((i) => _entry(i, cs)).toList(),
      onSelected: (v) {
        widget.onChanged(v);
        _focus.unfocus();
      },
    );
  }
}
