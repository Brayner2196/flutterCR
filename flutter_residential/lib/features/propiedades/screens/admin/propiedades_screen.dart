import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_propiedad_nodo.dart';
import '../../models/valor_tipo_propiedad.dart';
import '../../providers/propiedad_provider.dart';
import '../../services/propiedad_service.dart';
import '../../widgets/valor_propiedad_dropdown.dart';
import '../../widgets/valores_tipo_sheet.dart';

class PropiedadesScreen extends StatefulWidget {
  const PropiedadesScreen({super.key});

  @override
  State<PropiedadesScreen> createState() => _PropiedadesScreenState();
}

class _PropiedadesScreenState extends State<PropiedadesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarTiposAdmin();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propiedades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Tipos'),
            Tab(icon: Icon(Icons.home_work_outlined), text: 'Unidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TiposTab(),
          _UnidadesTab(),
        ],
      ),
    );
  }
}

class _TiposTab extends StatefulWidget {
  const _TiposTab();

  @override
  State<_TiposTab> createState() => _TiposTabState();
}

class _TiposTabState extends State<_TiposTab> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropiedadProvider>();
    final theme = Theme.of(context);

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!,
                style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => provider.cargarTiposAdmin(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (provider.tiposArbol.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_outlined,
                    size: 60, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('No hay tipos de propiedad',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Agrega el primer tipo con el botón +',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tiposArbol.length,
            itemBuilder: (_, i) =>
                _TipoNodoWidget(nodo: provider.tiposArbol[i], indent: 0),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'fab_tipos',
            onPressed: () => _mostrarDialogTipo(context, null, null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _mostrarDialogTipo(BuildContext context, TipoPropiedadNodo? nodo,
      TipoPropiedadNodo? parent) {
    showDialog(
      context: context,
      builder: (_) => _TipoDialog(
        nodoExistente: nodo,
        parentId: parent?.id,
        parentNombre: parent?.nombre,
        onGuardado: () => context.read<PropiedadProvider>().cargarTiposAdmin(),
      ),
    );
  }
}

class _TipoNodoWidget extends StatelessWidget {
  final TipoPropiedadNodo nodo;
  final int indent;

  const _TipoNodoWidget({required this.nodo, required this.indent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.only(left: indent * 16.0, bottom: 4, top: 4),
          child: ListTile(
            leading: Icon(
              nodo.esHoja ? Icons.door_front_door_outlined : Icons.folder_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(nodo.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: nodo.descripcion != null
                ? Text(nodo.descripcion!, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!nodo.activo)
                  Chip(
                    label: const Text('Inactivo'),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) => _onAction(context, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'valores', child: Text('Valores permitidos')),
                    const PopupMenuItem(
                        value: 'editar', child: Text('Editar')),
                    const PopupMenuItem(
                        value: 'hijo', child: Text('Agregar hijo')),
                    const PopupMenuItem(
                        value: 'desactivar', child: Text('Desactivar')),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final hijo in nodo.hijos)
          _TipoNodoWidget(nodo: hijo, indent: indent + 1),
      ],
    );
  }

  void _onAction(BuildContext context, String action) {
    final provider = context.read<PropiedadProvider>();
    if (action == 'valores') {
      // Diferir al siguiente frame para no chocar con el cierre del PopupMenu.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ValoresTipoSheet.mostrar(context, tipoId: nodo.id, tipoNombre: nodo.nombre);
      });
    } else if (action == 'editar') {
      showDialog(
        context: context,
        builder: (_) => _TipoDialog(
          nodoExistente: nodo,
          onGuardado: provider.cargarTiposAdmin,
        ),
      );
    } else if (action == 'hijo') {
      showDialog(
        context: context,
        builder: (_) => _TipoDialog(
          parentId: nodo.id,
          parentNombre: nodo.nombre,
          onGuardado: provider.cargarTiposAdmin,
        ),
      );
    } else if (action == 'desactivar') {
      PropiedadService.desactivarTipo(nodo.id).then((_) {
        if (context.mounted) provider.cargarTiposAdmin();
      });
    }
  }
}

class _TipoDialog extends StatefulWidget {
  final TipoPropiedadNodo? nodoExistente;
  final int? parentId;
  final String? parentNombre;
  final VoidCallback onGuardado;

  const _TipoDialog({
    this.nodoExistente,
    this.parentId,
    this.parentNombre,
    required this.onGuardado,
  });

  @override
  State<_TipoDialog> createState() => _TipoDialogState();
}

class _TipoDialogState extends State<_TipoDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  bool _guardando = false;

  bool get _esEdicion => widget.nodoExistente != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl =
        TextEditingController(text: widget.nodoExistente?.nombre ?? '');
    _descCtrl =
        TextEditingController(text: widget.nodoExistente?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await PropiedadService.actualizarTipo(
          widget.nodoExistente!.id,
          nombre: _nombreCtrl.text.trim(),
          descripcion:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
      } else {
        await PropiedadService.crearTipo(
          nombre: _nombreCtrl.text.trim(),
          descripcion:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          parentId: widget.parentId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
      }
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
      title: Text(_esEdicion
          ? 'Editar tipo'
          : widget.parentNombre != null
              ? 'Agregar subtipo de ${widget.parentNombre}'
              : 'Nuevo tipo raíz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción (aparece como hint en el registro)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

class _UnidadesTab extends StatefulWidget {
  const _UnidadesTab();

  @override
  State<_UnidadesTab> createState() => _UnidadesTabState();
}

class _UnidadesTabState extends State<_UnidadesTab> {
  List<Map<String, dynamic>> _propiedades = [];
  bool _cargando = false;
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
      _propiedades = await PropiedadService.listarPropiedades();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (_propiedades.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 60, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('No hay unidades registradas',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Las unidades se crean cuando los residentes se registran\no puedes crearlas manualmente con el botón +',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _propiedades.length,
            itemBuilder: (_, i) {
              final p = _propiedades[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.home_outlined,
                      color: theme.colorScheme.primary),
                  title: Text(p['pathTexto'] ?? ''),
                  subtitle: Text(p['estado'] ?? ''),
                  trailing: Text(
                    '${(p['residentes'] as List?)?.length ?? 0} residente(s)',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_unidades_refresh',
                onPressed: _cargar,
                tooltip: 'Actualizar',
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'fab_unidades_crear',
                onPressed: _crearUnidad,
                icon: const Icon(Icons.add),
                label: const Text('Crear unidad'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _crearUnidad() async {
    final tipos = context.read<PropiedadProvider>().tiposArbol;
    if (tipos.isEmpty) {
      await context.read<PropiedadProvider>().cargarTiposAdmin();
    }
    if (!mounted) return;
    final creada = await showDialog<bool>(
      context: context,
      builder: (_) => _CrearUnidadDialog(
        tiposRaiz: context.read<PropiedadProvider>().tiposArbol,
      ),
    );
    if (creada == true) _cargar();
  }
}

// ─── Diálogo: crear unidad con dropdowns encadenados ──────────────────────────

class _CrearUnidadDialog extends StatefulWidget {
  final List<TipoPropiedadNodo> tiposRaiz;
  const _CrearUnidadDialog({required this.tiposRaiz});

  @override
  State<_CrearUnidadDialog> createState() => _CrearUnidadDialogState();
}

class _CrearUnidadDialogState extends State<_CrearUnidadDialog> {
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

  bool get _completo =>
      _valores.isNotEmpty && _valores.every((v) => v != null);

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
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: (_completo && !_guardando) ? _guardar : null,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}
