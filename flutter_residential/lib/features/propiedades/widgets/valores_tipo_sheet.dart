import 'package:flutter/material.dart';
import '../models/valor_tipo_propiedad.dart';
import '../services/propiedad_service.dart';

/// Pantalla para gestionar los valores permitidos (plantilla global) de un tipo
/// de propiedad. Estos valores alimentan los dropdowns del registro/creación de
/// unidades, evitando que se ingresen valores libres.
///
/// Usa solo widgets estándar (Scaffold + ListView + ListTile) para máxima
/// robustez de layout. Reutilizable desde el módulo de tipos y desde propiedades.
class ValoresTipoSheet extends StatefulWidget {
  final int tipoId;
  final String tipoNombre;
  final Color color;

  const ValoresTipoSheet({
    super.key,
    required this.tipoId,
    required this.tipoNombre,
    this.color = Colors.teal,
  });

  /// Abre la pantalla de gestión de valores.
  static Future<void> mostrar(
    BuildContext context, {
    required int tipoId,
    required String tipoNombre,
    Color color = Colors.teal,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ValoresTipoSheet(
          tipoId: tipoId,
          tipoNombre: tipoNombre,
          color: color,
        ),
      ),
    );
  }

  @override
  State<ValoresTipoSheet> createState() => _ValoresTipoSheetState();
}

class _ValoresTipoSheetState extends State<ValoresTipoSheet> {
  List<ValorTipoPropiedad> _valores = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final todos = await PropiedadService.getValoresTodos(widget.tipoId);
      // Solo plantilla global (parentValorId == null).
      _valores = todos.where((v) => v.parentValorId == null).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final valor = await _pedirValor();
    if (valor == null || valor.trim().isEmpty) return;
    try {
      await PropiedadService.crearValor(widget.tipoId,
          valor: valor.trim(), orden: _valores.length);
      await _cargar();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _editar(ValorTipoPropiedad v) async {
    final valor = await _pedirValor(inicial: v.valor);
    if (valor == null || valor.trim().isEmpty) return;
    try {
      await PropiedadService.actualizarValor(v.id,
          valor: valor.trim(), orden: v.orden, activo: v.activo);
      await _cargar();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _toggleActivo(ValorTipoPropiedad v) async {
    try {
      if (v.activo) {
        await PropiedadService.desactivarValor(v.id);
      } else {
        await PropiedadService.actualizarValor(v.id,
            valor: v.valor, orden: v.orden, activo: true);
      }
      await _cargar();
    } catch (e) {
      _snack(e);
    }
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  Future<String?> _pedirValor({String? inicial}) {
    final ctrl = TextEditingController(text: inicial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(inicial == null ? 'Nuevo valor' : 'Editar valor'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Valor',
            hintText: 'Ej: A, 7, 07',
          ),
          onSubmitted: (t) => Navigator.pop(context, t),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Guardar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Valores de ${widget.tipoNombre}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        backgroundColor: widget.color,
        icon: const Icon(Icons.add),
        label: const Text('Agregar valor'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: widget.color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Estos son los valores que se podrán elegir para este nivel '
                        '(ej: A, B, C). Evita que se ingresen valores inválidos al registrar unidades.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: _valores.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.playlist_add,
                                        size: 48, color: cs.outlineVariant),
                                    const SizedBox(height: 12),
                                    Text('Aún no hay valores',
                                        style: theme.textTheme.titleSmall),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Agrega el primero con el botón "Agregar valor".',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                              itemCount: _valores.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (_, i) {
                                final v = _valores[i];
                                return Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(
                                      v.activo
                                          ? Icons.check_circle
                                          : Icons.block,
                                      color: v.activo
                                          ? widget.color
                                          : cs.outline,
                                    ),
                                    title: Text(
                                      v.valor,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: v.activo
                                            ? null
                                            : TextDecoration.lineThrough,
                                        color:
                                            v.activo ? null : cs.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Editar',
                                          onPressed: () => _editar(v),
                                        ),
                                        IconButton(
                                          icon: Icon(v.activo
                                              ? Icons.block
                                              : Icons.refresh),
                                          color: v.activo
                                              ? Colors.orange
                                              : Colors.teal,
                                          tooltip: v.activo
                                              ? 'Desactivar'
                                              : 'Reactivar',
                                          onPressed: () => _toggleActivo(v),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
