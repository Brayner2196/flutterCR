import 'package:flutter/material.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../models/usuario_response.dart';
import '../../models/usuario_propiedad_response.dart';
import '../../../propiedades/models/tipo_propiedad_nodo.dart';
import '../../../propiedades/models/valor_tipo_propiedad.dart';
import '../../../propiedades/widgets/valor_propiedad_dropdown.dart';
import '../../providers/usuario_provider.dart';
import '../../services/usuario_service.dart';
import '../../../propiedades/services/propiedad_service.dart';
import '../../../pagos/screens/admin/admin_ver_como_residente_screen.dart';

class UsuarioDetalleSheet extends StatelessWidget {
  final UsuarioResponse usuario;
  final bool mostrarAcciones;
  final bool esAdmin;

  const UsuarioDetalleSheet({
    super.key,
    required this.usuario,
    this.mostrarAcciones = false,
    this.esAdmin = false,
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
                      child: _TextoDesplazable(
                        texto: usuario.nombre,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        centered: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (mostrarAcciones) ...[_BotonesAprobacion(usuario: usuario)],

                    const SizedBox(height: 24),

                    if (esAdmin) ...[
                      _AdminControlesSection(
                        usuario: usuario,
                        onCambiado: () => context.read<UsuarioProvider>().cargarTodos(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _seccion(theme, 'Información general', [
                      _fila(theme, 'Rol', _etiquetaRol(usuario.rol)),
                      _fila(theme, 'Estado', usuario.estado),
                      _fila(theme, 'Registrado', DateFormatter.fechaHoraMinSegAmPm(usuario.creadoEn)),
                    ]),

                      const SizedBox(height: 16),
                      _seccion(theme, 'Datos de contacto', [
                          _fila(theme, 'Correo Electrónico', usuario.email, scrollable: true),
                        if (usuario.telefono != null)
                          _fila(theme, 'Teléfono', usuario.telefono!),
                      ]),
                    

                    if (usuario.rol == 'PROPIETARIO' || usuario.rol == 'INQUILINO') ...[
                      const SizedBox(height: 16),
                      _PropiedadesSection(usuario: usuario),
                      const SizedBox(height: 16),
                      _BotonVerComoResidente(usuario: usuario),
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: filas),
        ),
      ],
    );
  }

  Widget _fila(ThemeData theme, String label, String valor,
      {bool scrollable = false}) {
    final valorStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
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
          const SizedBox(width: 12),
          if (scrollable)
            Flexible(
              child: _TextoDesplazable(texto: valor, style: valorStyle),
            )
          else
            Flexible(
              child: Text(
                valor,
                style: valorStyle,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
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
      case 'PROPIETARIO':
        return 'Propietario';
      case 'INQUILINO':
        return 'Inquilino';
      case 'PROPIETARIO_PENDIENTE':
        return 'Pendiente de aprobación';
      case 'VIGILANTE':
        return 'Vigilante';
      case 'PORTERO':
        return 'Portero';
      case 'PISCINERO':
        return 'Piscinero';
      case 'CONTADOR':
        return 'Contador';
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
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.4),
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
          if(prop.pathTexto.contains('Parqueadero')) 
          Icon(
            Icons.emoji_transportation_outlined,
            color: theme.colorScheme.primary, size: 22
          )else
          Icon(
            Icons.home_outlined,
            color: theme.colorScheme.primary, size: 22
          ),
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
                      Row(
                        children: [
                          const Icon(Icons.verified,
                                  size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
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
                        ],
                      ),
                      const SizedBox(width: 6),
                    ],
                    if(prop.estadoPropiedad.isNotEmpty && prop.estadoPropiedad == 'OCUPADO')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ocupado',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error),
                        ),
                      ),
                    if(prop.estadoPropiedad.isNotEmpty && prop.estadoPropiedad == 'DISPONIBLE')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Disponible',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary),
                        ),
                      ),
                      if(prop.estadoPropiedad.isNotEmpty && prop.estadoPropiedad == 'EN_MANTENIMIENTO')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'En mantenimiento',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(width: 6),
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
        initialValue: _estadoSeleccionado,
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
  /// Rutas completas hacia cada unidad asignable (ej. Apartamento → [Torre, Piso, Apartamento]).
  List<List<TipoPropiedadNodo>> _rutasFacturables = [];

  /// Ruta seleccionada; su `.last` es la hoja mostrada en el dropdown (ej. Apartamento).
  List<TipoPropiedadNodo>? _rutaSeleccionada;

  /// Valor elegido del catálogo por cada nivel de la ruta seleccionada.
  final List<ValorTipoPropiedad?> _valoresSeleccionados = [];

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await PropiedadService.getTiposArbolAdmin();
      if (mounted) {
        setState(() {
          _rutasFacturables = TipoPropiedadNodo.rutasFacturables(tipos);
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

  List<TipoPropiedadNodo> get _niveles => _rutaSeleccionada ?? const [];

  bool get _esValido =>
      _rutaSeleccionada != null &&
      _valoresSeleccionados.isNotEmpty &&
      _valoresSeleccionados.every((v) => v != null);

  void _onRutaChanged(List<TipoPropiedadNodo>? ruta) {
    _valoresSeleccionados
      ..clear()
      ..addAll(List.filled(ruta?.length ?? 0, null));
    setState(() => _rutaSeleccionada = ruta);
  }

  /// Al elegir un valor, se limpian los niveles hijos (dependen del padre).
  void _onValorSeleccionado(int index, ValorTipoPropiedad? valor) {
    _valoresSeleccionados[index] = valor;
    for (int j = index + 1; j < _valoresSeleccionados.length; j++) {
      _valoresSeleccionados[j] = null;
    }
    setState(() {});
  }

  Future<void> _guardar() async {
    if (!_esValido) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona la propiedad y completa todos los niveles')));
      return;
    }
    setState(() => _guardando = true);
    try {
      final path = List.generate(
        _niveles.length,
        (i) => {
          'tipoId': _niveles[i].id,
          'valor': _valoresSeleccionados[i]!.valor,
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
              : _rutasFacturables.isEmpty
                  ? const Text(
                      'No hay unidades asignables configuradas.\nMarca un tipo como facturable en Configuración → Tipos de propiedad.')
                  : SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Dropdown solo con la unidad final asignable (ej. Apartamento)
                            DropdownButtonFormField<List<TipoPropiedadNodo>>(
                              initialValue: _rutaSeleccionada,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de propiedad *',
                                prefixIcon: Icon(Icons.home_work_outlined),
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Selecciona la unidad...'),
                              items: _rutasFacturables
                                  .map((ruta) => DropdownMenuItem(
                                        value: ruta,
                                        child: Text(ruta.last.nombre),
                                      ))
                                  .toList(),
                              onChanged: _onRutaChanged,
                            ),
                            // Un buscador por cada nivel de la jerarquía (solo catálogo)
                            for (int i = 0; i < _niveles.length; i++) ...[
                              const SizedBox(height: 12),
                              ValorPropiedadDropdown(
                                key: ValueKey(
                                    'nivel_${_niveles[i].id}_${i == 0 ? 'raiz' : _valoresSeleccionados[i - 1]?.id}'),
                                label: _niveles[i].nombre,
                                dependencyKey: i == 0
                                    ? 'raiz'
                                    : _valoresSeleccionados[i - 1]?.id,
                                loader: () => PropiedadService.getValoresAdmin(
                                  _niveles[i].id,
                                  parentValorId: i == 0
                                      ? null
                                      : _valoresSeleccionados[i - 1]?.id,
                                ),
                                onChanged: (v) => _onValorSeleccionado(i, v),
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
        if (!_cargando && _error == null && _rutasFacturables.isNotEmpty)
          FilledButton(
            onPressed: (_guardando || !_esValido) ? null : _guardar,
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

// ── Admin: toggle activo + cambio de rol ─────────────────────────────────────

class _AdminControlesSection extends StatefulWidget {
  final UsuarioResponse usuario;
  final VoidCallback onCambiado;

  const _AdminControlesSection({required this.usuario, required this.onCambiado});

  @override
  State<_AdminControlesSection> createState() => _AdminControlesSectionState();
}

class _AdminControlesSectionState extends State<_AdminControlesSection> {
  late bool _activo;
  late String _rolActual;
  bool _cargando = false;

  static const _rolesDisponibles = [
    'PROPIETARIO',
    'INQUILINO',
    'VIGILANTE',
    'PORTERO',
    'PISCINERO',
    'CONTADOR',
    'TENANT_ADMIN',
  ];

  static const _rolesLabel = {
    'PROPIETARIO': 'Propietario',
    'INQUILINO': 'Inquilino',
    'VIGILANTE': 'Vigilante',
    'PORTERO': 'Portero',
    'PISCINERO': 'Piscinero',
    'CONTADOR': 'Contador',
    'TENANT_ADMIN': 'Administrador',
  };

  @override
  void initState() {
    super.initState();
    _activo = widget.usuario.activo;
    _rolActual = widget.usuario.rol;
  }

  Future<void> _toggleActivo(bool nuevo) async {
    setState(() => _cargando = true);
    try {
      if (nuevo) {
        await UsuarioService.activar(widget.usuario.id);
      } else {
        await UsuarioService.desactivar(widget.usuario.id);
      }
      setState(() => _activo = nuevo);
      widget.onCambiado();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarRol(String nuevoRol) async {
    if (nuevoRol == _rolActual) return;
    setState(() => _cargando = true);
    try {
      await UsuarioService.cambiarRol(widget.usuario.id, nuevoRol);
      setState(() => _rolActual = nuevoRol);
      widget.onCambiado();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Rol cambiado a ${_rolesLabel[nuevoRol] ?? nuevoRol}'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Sólo mostrar roles válidos; si el rol actual no está en la lista, lo incluimos
    final rolesOpciones = _rolesDisponibles.contains(_rolActual)
        ? _rolesDisponibles
        : [_rolActual, ..._rolesDisponibles];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Control de acceso',
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Toggle activo
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  _activo ? 'Cuenta activa' : 'Cuenta desactivada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _activo ? null : cs.error,
                  ),
                ),
                subtitle: Text(
                  _activo
                      ? 'El usuario puede iniciar sesión'
                      : 'El usuario no puede iniciar sesión',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                secondary: Icon(
                  _activo ? Icons.lock_open_outlined : Icons.lock_outlined,
                  color: _activo ? Colors.green : cs.error,
                ),
                value: _activo,
                onChanged: _cargando ? null : _toggleActivo,
              ),

              Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),

              // Selector de rol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: cs.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: rolesOpciones.contains(_rolActual) ? _rolActual : null,
                        decoration: InputDecoration(
                          labelText: 'Rol del usuario',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        items: rolesOpciones
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(_rolesLabel[r] ?? r,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: _cargando
                            ? null
                            : (v) {
                                if (v != null) _cambiarRol(v);
                              },
                      ),
                    ),
                  ],
                ),
              ),

              if (_cargando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Texto con desplazamiento automático (marquee) ────────────────────────────

class _TextoDesplazable extends StatefulWidget {
  final String texto;
  final TextStyle? style;
  final bool centered;

  const _TextoDesplazable({
    required this.texto,
    this.style,
    this.centered = false,
  });

  @override
  State<_TextoDesplazable> createState() => _TextoDesplazableState();
}

class _TextoDesplazableState extends State<_TextoDesplazable> {
  late final ScrollController _ctrl;
  bool _corriendo = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
  }

  @override
  void dispose() {
    _corriendo = false;
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loop() async {
    _corriendo = true;
    // Espera inicial para que el layout se estabilice
    await Future.delayed(const Duration(milliseconds: 1500));
    while (_corriendo && mounted) {
      if (!_ctrl.hasClients) break;
      final max = _ctrl.position.maxScrollExtent;
      if (max <= 0) break; // No hay overflow: detiene el loop

      // Duración proporcional a la distancia (≈20 ms/px)
      final ms = (max * 20).clamp(800, 6000).toInt();
      await _ctrl.animateTo(
        max,
        duration: Duration(milliseconds: ms),
        curve: Curves.linear,
      );
      if (!_corriendo || !mounted) break;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_corriendo || !mounted) break;
      await _ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      if (!_corriendo || !mounted) break;
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _ctrl,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.texto,
        style: widget.style,
        textAlign: widget.centered ? TextAlign.center : TextAlign.end,
        softWrap: false,
      ),
    );
  }
}

// ── Botón: ver como residente ─────────────────────────────────────────────────

class _BotonVerComoResidente extends StatelessWidget {
  final UsuarioResponse usuario;
  const _BotonVerComoResidente({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Ver como residente'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminVerComoResidenteScreen(
                usuarioId: usuario.id,
                usuarioNombre: usuario.nombre,
              ),
            ),
          );
        },
      ),
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

  Future<void> _mostrarMenuAprobacion(BuildContext context) async {
    final provider = context.read<UsuarioProvider>();
    final rolSeleccionado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aprobar como...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Propietario'),
              subtitle: const Text('Puede gestionar inquilinos de su unidad'),
              onTap: () => Navigator.of(ctx).pop('PROPIETARIO'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Inquilino'),
              subtitle: const Text('Acceso según permisos otorgados por el propietario'),
              onTap: () => Navigator.of(ctx).pop('INQUILINO'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (rolSeleccionado == null) return;

    await _accion(
      fn: () => provider.aprobar(widget.usuario.id, rolDestino: rolSeleccionado),
      successTitulo: 'Usuario aprobado',
      successDescripcion:
          '${widget.usuario.nombre} fue aprobado como $rolSeleccionado.',
    );
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
            onPressed: _cargando ? null : () => _mostrarMenuAprobacion(context),
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
