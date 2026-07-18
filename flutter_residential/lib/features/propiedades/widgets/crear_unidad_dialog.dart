import 'package:flutter/material.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../models/valor_tipo_propiedad.dart';
import '../services/propiedad_service.dart';
import 'valor_propiedad_dropdown.dart';

/// Diálogo reutilizable para crear una unidad (propiedad) mediante dropdowns
/// encadenados del catálogo. Devuelve `true` en [Navigator.pop] si se creó.
class CrearUnidadDialog extends StatefulWidget {
  final List<TipoPropiedadNodo> tiposRaiz;

  const CrearUnidadDialog({super.key, required this.tiposRaiz});

  @override
  State<CrearUnidadDialog> createState() => _CrearUnidadDialogState();
}

class _CrearUnidadDialogState extends State<CrearUnidadDialog> {
  // Rutas raíz→hoja del árbol y sus hojas (tipos finales, ej. Apartamento).
  late final List<List<TipoPropiedadNodo>> _rutas;
  late final List<TipoPropiedadNodo> _hojas;
  TipoPropiedadNodo? _hoja;

  final List<TipoPropiedadNodo> _niveles = [];
  final List<ValorTipoPropiedad?> _valores = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _rutas = TipoPropiedadNodo.rutasHoja(widget.tiposRaiz);
    _hojas = _rutas.map((r) => r.last).toList();
  }

  /// Al elegir la unidad final se reconstruye toda la ruta raíz→hoja para pedir
  /// los valores de cada nivel (ej. Torre, Piso, Apartamento).
  void _onHoja(TipoPropiedadNodo? hoja) {
    _niveles.clear();
    _valores.clear();
    if (hoja != null) {
      final ruta = _rutas.firstWhere((r) => r.last == hoja);
      _niveles.addAll(ruta);
      _valores.addAll(List<ValorTipoPropiedad?>.filled(ruta.length, null));
    }
    setState(() => _hoja = hoja);
  }

  void _onValor(int index, ValorTipoPropiedad? valor) {
    _valores[index] = valor;
    // Los niveles están fijados por la hoja; solo reseteo los valores de los
    // niveles inferiores, que dependen del valor padre.
    for (int j = index + 1; j < _valores.length; j++) {
      _valores[j] = null;
    }
    setState(() {});
  }

  bool get _completo => _valores.isNotEmpty && _valores.every((v) => v != null);

  Future<void> _guardar() async {
    if (!_completo) return;
    setState(() => _guardando = true);
    try {
      final path = <Map<String, dynamic>>[];
      for (int i = 0; i < _niveles.length; i++) {
        path.add({'tipoId': _niveles[i].id, 'valor': _valores[i]!.valor});
      }
      await PropiedadService.crearPropiedad(path);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear unidad'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hojas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No hay tipos de propiedad configurados.'),
                )
              else
                DropdownButtonFormField<TipoPropiedadNodo>(
                  initialValue: _hoja,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de propiedad',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items: _hojas
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.nombre)))
                      .toList(),
                  onChanged: _onHoja,
                ),
              for (int i = 0; i < _niveles.length; i++) ...[
                const SizedBox(height: 12),
                ValorPropiedadDropdown(
                  key: ValueKey(
                      'u_${_niveles[i].id}_${i == 0 ? 'raiz' : _valores[i - 1]?.id}'),
                  label: _niveles[i].nombre,
                  dependencyKey: i == 0 ? 'raiz' : _valores[i - 1]?.id,
                  loader: () => PropiedadService.getValoresAdmin(
                    _niveles[i].id,
                    parentValorId: i == 0 ? null : _valores[i - 1]?.id,
                  ),
                  onChanged: (v) => _onValor(i, v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_completo && !_guardando) ? _guardar : null,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
