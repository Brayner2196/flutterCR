import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../models/usuario_response.dart';
import '../../../models/usuario_propiedad_response.dart';
import '../../../models/tipo_propiedad_nodo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../services/propiedad_service.dart';

class UsuarioDetalleSheet extends StatelessWidget {
  final UsuarioResponse usuario;
  final bool mostrarAcciones;

  const UsuarioDetalleSheet({
    super.key,
    required this.usuario,
    this.mostrarAcciones = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    // Avatar y nombre
                    Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          usuario.nombre.isNotEmpty
                              ? usuario.nombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        usuario.nombre,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: Text(
                        usuario.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (mostrarAcciones) ...[_BotonesAprobacion(usuario: usuario)],

                    const SizedBox(height: 24),

                    _seccion(theme, 'Información general', [
                      _fila(theme, 'Rol', _etiquetaRol(usuario.rol)),
                      _fila(theme, 'Estado', usuario.estado),
                      _fila(theme, 'Registrado', usuario.creadoEn),
                    ]),

                    if (usuario.apto != null ||
                        usuario.torre != null ||
                        usuario.telefono != null) ...[
                      const SizedBox(height: 16),
                      _seccion(theme, 'Residencia', [
                        if (usuario.torre != null)
                          _fila(theme, 'Torre', usuario.torre!),
                        if (usuario.apto != null)
                          _fila(theme, 'Apartamento', usuario.apto!),
                        if (usuario.telefono != null)
                          _fila(theme, 'Teléfono', usuario.telefono!),
                      ]),
                    ],

                    if (usuario.rol == 'RESIDENTE') ...[  
                      const SizedBox(height: 16),
                      _PropiedadesSection(usuario: usuario),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _seccion(ThemeData theme, String titulo, List<Widget> filas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: filas),
        ),
      ],
    );
  }

  Widget _fila(ThemeData theme, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            valor,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _etiquetaRol(String rol) {
    switch (rol) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'TENANT_ADMIN':
        return 'Administrador';
      case 'RESIDENTE':
        return 'Residente';
      default:
        return rol;
    }
  }
}

// ── Sección de Propiedades ────────────────────────────────────────────────────

class _PropiedadesSection extends StatefulWidget {
  final UsuarioResponse usuario;

  const _PropiedadesSection({required this.usuario});

  @override
  State<_PropiedadesSection> createState() => _PropiedadesSectionState();
}

class _PropiedadesSectionState extends State<_PropiedadesSection> {
  List<UsuarioPropiedadResponse> _propiedades = [];
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
      final lista =
          await PropiedadService.getPropiedadesDeUsuario(widget.usuario.id);
      if (mounted) setState(() => _propiedades = lista);
    } catch (e) {
      if (mounted)
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _quitar(UsuarioPropiedadResponse prop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar propiedad'),
        content: Text(
            '¿Quitar "${prop.pathTexto}" de ${widget.usuario.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await PropiedadService.quitarUsuario(
          prop.propiedadId, widget.usuario.id);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _marcarPrincipal(UsuarioPropiedadResponse prop) async {
    try {
      await PropiedadService.marcarComoPrincipal(
          prop.propiedadId, widget.usuario.id);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  void _cambiarEstado(UsuarioPropiedadResponse prop) {
    showDialog(
      context: context,
      builder: (_) => _CambiarEstadoDialog(
        propiedadId: prop.propiedadId,
        onGuardado: _cargar,
      ),
    );
  }

  void _abrirAgregar() {
    showDialog(
      context: context,
      builder: (_) => _AgregarPropiedadDialog(
        usuario: widget.usuario,
        onAsignado: _cargar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Propiedades',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_home_outlined),
              tooltip: 'Agregar propiedad',
              onPressed: _abrirAgregar,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style:
                            TextStyle(color: theme.colorScheme.error))),
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _cargar),
              ],
            ),
          )
        else if (_propiedades.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.home_outlined,
                      size: 40, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    'Sin propiedades asignadas',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _propiedades
                  .map((prop) => _PropiedadTile(
                        prop: prop,
                        onQuitar: () => _quitar(prop),
                        onMarcarPrincipal:
                            prop.esPrincipal ? null : () => _marcarPrincipal(prop),
                        onCambiarEstado: () => _cambiarEstado(prop),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ── Tile individual de propiedad ──────────────────────────────────────────────

class _PropiedadTile extends StatelessWidget {
  final UsuarioPropiedadResponse prop;
  final VoidCallback onQuitar;
  final VoidCallback? onMarcarPrincipal;
  final VoidCallback onCambiarEstado;

  const _PropiedadTile({
    required this.prop,
    required this.onQuitar,
    required this.onMarcarPrincipal,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.home_outlined,
              color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop.pathTexto,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (prop.esPrincipal) ...[  
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Principal',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      prop.nombreTipoRaiz,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: theme.colorScheme.onSurfaceVariant),
            onSelected: (action) {
              if (action == 'principal') onMarcarPrincipal?.call();
              if (action == 'estado') onCambiarEstado();
              if (action == 'quitar') onQuitar();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'principal',
                enabled: onMarcarPrincipal != null,
                child: const Row(
                  children: [
                    Icon(Icons.star_outline),
                    SizedBox(width: 8),
                    Text('Marcar como principal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'estado',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Cambiar estado'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quitar',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Quitar propiedad',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dialog: Cambiar estado de propiedad ───────────────────────────────────────

class _CambiarEstadoDialog extends StatefulWidget {
  final int propiedadId;
  final VoidCallback onGuardado;

  const _CambiarEstadoDialog(
      {required this.propiedadId, required this.onGuardado});

  @override
  State<_CambiarEstadoDialog> createState() => _CambiarEstadoDialogState();
}

class _CambiarEstadoDialogState extends State<_CambiarEstadoDialog> {
  static const _estados = [
    'DISPONIBLE',
    'OCUPADO',
    'EN_MANTENIMIENTO',
    'VENDIDO',
  ];
  String _estadoSeleccionado = 'OCUPADO';
  bool _guardando = false;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await PropiedadService.actualizarEstadoPropiedad(
          widget.propiedadId, _estadoSeleccionado);
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
      title: const Text('Cambiar estado'),
      content: DropdownButtonFormField<String>(
        value: _estadoSeleccionado,
        decoration: const InputDecoration(labelText: 'Estado'),
        items: _estados
            .map((e) => DropdownMenuItem(
                value: e, child: Text(_etiquetaEstado(e))))
            .toList(),
        onChanged: (v) => setState(() => _estadoSeleccionado = v!),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }

  String _etiquetaEstado(String e) {
    switch (e) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'OCUPADO':
        return 'Ocupado';
      case 'EN_MANTENIMIENTO':
        return 'En mantenimiento';
      case 'VENDIDO':
        return 'Vendido';
      default:
        return e;
    }
  }
}

// ── Dialog: Agregar propiedad al residente ────────────────────────────────────

class _AgregarPropiedadDialog extends StatefulWidget {
  final UsuarioResponse usuario;
  final VoidCallback onAsignado;

  const _AgregarPropiedadDialog(
      {required this.usuario, required this.onAsignado});

  @override
  State<_AgregarPropiedadDialog> createState() =>
      _AgregarPropiedadDialogState();
}

class _AgregarPropiedadDialogState extends State<_AgregarPropiedadDialog> {
  List<TipoPropiedadNodo> _camino = [];
  List<TextEditingController> _controllers = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await PropiedadService.getTiposArbolAdmin();
      final camino = _aplanarCamino(tipos);
      if (mounted) {
        setState(() {
          _camino = camino;
          _controllers =
              List.generate(camino.length, (_) => TextEditingController());
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _cargando = false;
        });
      }
    }
  }

  /// Recorre el árbol tomando siempre el primer hijo hasta llegar a la hoja.
  List<TipoPropiedadNodo> _aplanarCamino(List<TipoPropiedadNodo> raices) {
    final resultado = <TipoPropiedadNodo>[];
    TipoPropiedadNodo? actual = raices.isNotEmpty ? raices.first : null;
    while (actual != null) {
      resultado.add(actual);
      actual = actual.hijos.isNotEmpty ? actual.hijos.first : null;
    }
    return resultado;
  }

  Future<void> _guardar() async {
    for (final c in _controllers) {
      if (c.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completa todos los campos')));
        return;
      }
    }
    setState(() => _guardando = true);
    try {
      final path = List.generate(
        _camino.length,
        (i) => {
          'tipoId': _camino[i].id,
          'valor': _controllers[i].text.trim(),
        },
      );
      final propiedadId = await PropiedadService.crearPropiedad(path);
      await PropiedadService.asignarUsuario(propiedadId, widget.usuario.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onAsignado();
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
      title: Text('Agregar propiedad a ${widget.usuario.nombre}'),
      content: _cargando
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error))
              : _camino.isEmpty
                  ? const Text('No hay tipos de propiedad configurados.')
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _camino.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _controllers[i],
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: InputDecoration(
                                  labelText: '${_camino[i].nombre} *'),
                            ),
                          ),
                        ),
                      ),
                    ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        if (!_cargando && _error == null && _camino.isNotEmpty)
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Agregar'),
          ),
      ],
    );
  }
}

// ── Botones de aprobación ─────────────────────────────────────────────────────

class _BotonesAprobacion extends StatefulWidget {
  final UsuarioResponse usuario;
  const _BotonesAprobacion({required this.usuario});

  @override
  State<_BotonesAprobacion> createState() => _BotonesAprobacionState();
}

class _BotonesAprobacionState extends State<_BotonesAprobacion> {
  bool _cargando = false;

  void _mostrarToast({
    required ToastificationType tipo,
    required String titulo,
    required String descripcion,
  }) {
    toastification.show(
      context: context,
      type: tipo,
      style: ToastificationStyle.flatColored,
      title: Text(titulo),
      description: Text(descripcion),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      showProgressBar: true,
      closeOnClick: true,
    );
  }

  Future<void> _accion({
    required Future<void> Function() fn,
    required String successTitulo,
    required String successDescripcion,
  }) async {
    setState(() => _cargando = true);
    try {
      await fn();
      if (!mounted) return;
      _mostrarToast(
        tipo: ToastificationType.success,
        titulo: successTitulo,
        descripcion: successDescripcion,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _mostrarToast(
        tipo: ToastificationType.error,
        titulo: 'Error',
        descripcion: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UsuarioProvider>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _cargando
                ? null
                : () => _accion(
                      fn: () => provider.rechazar(widget.usuario.id),
                      successTitulo: 'Usuario rechazado',
                      successDescripcion:
                          '${widget.usuario.nombre} fue rechazado.',
                    ),
            icon: const Icon(Icons.close, color: Colors.red),
            label:
                const Text('Rechazar', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _cargando
                ? null
                : () => _accion(
                      fn: () => provider.aprobar(widget.usuario.id),
                      successTitulo: 'Usuario aprobado',
                      successDescripcion:
                          '${widget.usuario.nombre} fue aprobado correctamente.',
                    ),
            icon: _cargando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: const Text('Aprobar'),
          ),
        ),
      ],
    );
  }
}
