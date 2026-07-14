import 'package:flutter/material.dart';
import '../models/valor_tipo_propiedad.dart';

/// Firma del cargador de valores permitidos para un nivel.
/// La resolución (público vs admin, con parentValorId) la decide quien lo use.
typedef ValoresLoader = Future<List<ValorTipoPropiedad>> Function();

/// Dropdown con búsqueda (typeahead) que SOLO permite elegir un valor del
/// catálogo permitido de un tipo de propiedad. El usuario escribe, la lista se
/// filtra y elige una coincidencia — nunca un valor libre.
///
/// Reutilizable en registro público, wizard admin y gestión de unidades:
/// solo cambia el [loader] que se le pasa.
class ValorPropiedadDropdown extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color? color;

  /// Carga los valores permitidos del nivel. Se vuelve a invocar cuando cambia
  /// [dependencyKey] (típicamente el valor padre seleccionado).
  final ValoresLoader loader;

  /// Cambia cuando cambia el contexto del nivel (ej: el valor padre). Al cambiar,
  /// el dropdown se resetea y recarga sus opciones.
  final Object? dependencyKey;

  /// Notifica el valor elegido (o null si se limpió / recargó).
  final ValueChanged<ValorTipoPropiedad?> onChanged;

  final bool enabled;

  const ValorPropiedadDropdown({
    super.key,
    required this.label,
    required this.loader,
    required this.onChanged,
    this.icon = Icons.label_outline,
    this.color,
    this.dependencyKey,
    this.enabled = true,
  });

  @override
  State<ValorPropiedadDropdown> createState() => _ValorPropiedadDropdownState();
}

class _ValorPropiedadDropdownState extends State<ValorPropiedadDropdown> {
  List<ValorTipoPropiedad> _valores = [];
  ValorTipoPropiedad? _seleccionado;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant ValorPropiedadDropdown old) {
    super.didUpdateWidget(old);
    // Si cambió el contexto (valor padre), reseteo y recargo.
    if (old.dependencyKey != widget.dependencyKey) {
      _seleccionado = null;
      widget.onChanged(null);
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final valores = await widget.loader();
      if (!mounted) return;
      setState(() => _valores = valores);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary;

    if (_cargando) {
      return _wrapper(
        color,
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }

    if (_error != null) {
      return _wrapper(
        color,
        Row(
          children: [
            Expanded(child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 12))),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_valores.isEmpty) {
      return _wrapper(
        color,
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Sin valores configurados para ${widget.label}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return DropdownMenu<ValorTipoPropiedad>(
      enabled: widget.enabled,
      expandedInsets: EdgeInsets.zero,
      enableFilter: true,
      requestFocusOnTap: true,
      initialSelection: _seleccionado,
      label: Text(widget.label),
      leadingIcon: Icon(widget.icon, color: color),
      hintText: 'Escribe para buscar...',
      menuHeight: 280,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dropdownMenuEntries: _valores
          .map((v) => DropdownMenuEntry(value: v, label: v.valor))
          .toList(),
      onSelected: (v) {
        setState(() => _seleccionado = v);
        widget.onChanged(v);
      },
    );
  }

  Widget _wrapper(Color color, Widget child) => InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
}
