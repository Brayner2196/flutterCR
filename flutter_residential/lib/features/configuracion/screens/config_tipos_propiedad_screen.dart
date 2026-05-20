import 'package:flutter/material.dart';
import 'package:flutter_residential/features/propiedades/models/tipo_propiedad_nodo.dart';
import 'package:flutter_residential/features/propiedades/services/propiedad_service.dart';

class ConfigTiposPropiedadScreen extends StatefulWidget {
  const ConfigTiposPropiedadScreen({super.key});

  @override
  State<ConfigTiposPropiedadScreen> createState() =>
      _ConfigTiposPropiedadScreenState();
}

class _ConfigTiposPropiedadScreenState
    extends State<ConfigTiposPropiedadScreen> {
  List<TipoPropiedadNodo> _arbol = [];
  bool _cargando = true;

  final _coloresPorNivel = [
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.purple,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _arbol = await PropiedadService.getTiposArbolAdmin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarFormNodo({TipoPropiedadNodo? nodo, int? parentId, int nivel = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TipoNodoForm(
        nodo: nodo,
        parentId: parentId,
        nivel: nivel,
        onGuardado: _cargar,
      ),
    );
  }

  Future<void> _confirmarDesactivar(TipoPropiedadNodo nodo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar tipo'),
        content: Text(
            '¿Desactivar "${nodo.nombre}"? No se podrán crear nuevas propiedades de este tipo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await PropiedadService.desactivarTipo(nodo.id);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de propiedad'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormNodo(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo raíz'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _arbol.isEmpty
              ? _EmptyView(onCrear: () => _mostrarFormNodo())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'La jerarquía define cómo se organizan las unidades (ej: Torre → Piso → Apartamento). Los tipos marcados como "Facturable" generan cobros.',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._arbol.map((nodo) => _NodoTile(
                            nodo: nodo,
                            nivel: 0,
                            colores: _coloresPorNivel,
                            onEditar: (n, nivel) => _mostrarFormNodo(nodo: n, nivel: nivel),
                            onAgregarHijo: (n, nivel) => _mostrarFormNodo(parentId: n.id, nivel: nivel + 1),
                            onDesactivar: _confirmarDesactivar,
                          )),
                    ],
                  ),
                ),
    );
  }
}

// ── Tile recursivo de nodo ────────────────────────────────────────────────────

class _NodoTile extends StatefulWidget {
  final TipoPropiedadNodo nodo;
  final int nivel;
  final List<Color> colores;
  final void Function(TipoPropiedadNodo, int) onEditar;
  final void Function(TipoPropiedadNodo, int) onAgregarHijo;
  final void Function(TipoPropiedadNodo) onDesactivar;

  const _NodoTile({
    required this.nodo,
    required this.nivel,
    required this.colores,
    required this.onEditar,
    required this.onAgregarHijo,
    required this.onDesactivar,
  });

  @override
  State<_NodoTile> createState() => _NodoTileState();
}

class _NodoTileState extends State<_NodoTile> {
  bool _expandido = true;

  Color get _color => widget.colores[widget.nivel % widget.colores.length];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final nodo = widget.nodo;
    final tieneHijos = nodo.hijos.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: widget.nivel * 16.0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conector visual para hijos
          if (widget.nivel > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right_rounded,
                      size: 14, color: cs.outlineVariant),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: nodo.activo ? _color.withValues(alpha: 0.3) : cs.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: nodo.activo ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: nodo.activo ? _color : cs.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          nodo.nombre,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: nodo.activo ? null : cs.onSurfaceVariant,
                            decoration: nodo.activo ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (nodo.esFacturable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.5)),
                          ),
                          child: Text('Facturable',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800)),
                        ),
                      ],
                      if (!nodo.activo) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('Inactivo',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onErrorContainer)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: nodo.descripcion != null
                      ? Text(nodo.descripcion!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tieneHijos)
                        IconButton(
                          icon: Icon(
                            _expandido
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _expandido = !_expandido),
                          visualDensity: VisualDensity.compact,
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (v) {
                          if (v == 'editar') widget.onEditar(nodo, widget.nivel);
                          if (v == 'hijo') widget.onAgregarHijo(nodo, widget.nivel);
                          if (v == 'desactivar') widget.onDesactivar(nodo);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Editar')])),
                          const PopupMenuItem(value: 'hijo', child: Row(children: [Icon(Icons.add, size: 16), SizedBox(width: 8), Text('Agregar subnivel')])),
                          if (nodo.activo)
                            const PopupMenuItem(
                              value: 'desactivar',
                              child: Row(children: [
                                Icon(Icons.block_outlined, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Desactivar', style: TextStyle(color: Colors.orange)),
                              ]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hijos
          if (tieneHijos && _expandido)
            ...nodo.hijos.map((hijo) => _NodoTile(
                  nodo: hijo,
                  nivel: widget.nivel + 1,
                  colores: widget.colores,
                  onEditar: widget.onEditar,
                  onAgregarHijo: widget.onAgregarHijo,
                  onDesactivar: widget.onDesactivar,
                )),
        ],
      ),
    );
  }
}

// ── Formulario de nodo ────────────────────────────────────────────────────────

class _TipoNodoForm extends StatefulWidget {
  final TipoPropiedadNodo? nodo;
  final int? parentId;
  final int nivel;
  final VoidCallback onGuardado;

  const _TipoNodoForm({
    this.nodo,
    this.parentId,
    required this.nivel,
    required this.onGuardado,
  });

  @override
  State<_TipoNodoForm> createState() => _TipoNodoFormState();
}

class _TipoNodoFormState extends State<_TipoNodoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late bool _esFacturable;
  bool _guardando = false;

  bool get _esEdicion => widget.nodo != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nodo?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.nodo?.descripcion ?? '');
    _esFacturable = widget.nodo?.esFacturable ?? false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await PropiedadService.actualizarTipo(
          widget.nodo!.id,
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          esFacturable: _esFacturable,
        );
      } else {
        await PropiedadService.crearTipo(
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          parentId: widget.parentId,
          esFacturable: _esFacturable,
        );
      }
      widget.onGuardado();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _esEdicion ? 'Editar tipo' : 'Nuevo tipo de propiedad',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.parentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Subnivel del tipo seleccionado',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del tipo',
                hintText: 'Ej: Torre, Piso, Apartamento',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción / placeholder (opcional)',
                hintText: 'Ej: 101, A, Norte...',
                prefixIcon: const Icon(Icons.short_text),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            // Toggle facturable
            GestureDetector(
              onTap: () => setState(() => _esFacturable = !_esFacturable),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _esFacturable
                      ? Colors.amber.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _esFacturable
                        ? Colors.amber.shade600.withValues(alpha: 0.6)
                        : cs.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: _esFacturable ? Colors.amber.shade700 : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Facturable',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _esFacturable
                                      ? Colors.amber.shade800
                                      : cs.onSurface)),
                          Text(
                            'Las unidades de este tipo generan cobros mensuales',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _esFacturable,
                      onChanged: (v) => setState(() => _esFacturable = v),
                      activeColor: Colors.amber.shade700,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando...' : (_esEdicion ? 'Guardar cambios' : 'Crear tipo')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyView({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            const Text('Sin tipos de propiedad',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Define la jerarquía del conjunto\npara organizar las unidades',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear primer tipo'),
            ),
          ],
        ),
      ),
    );
  }
}
