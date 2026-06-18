import 'package:flutter/material.dart';
import 'package:flutter_residential/core/utils/texto_utils.dart';
import 'package:toastification/toastification.dart';
import '../services/inquilino_service.dart';
import '../widgets/crear_inquilino_dialog.dart';
import '../../../features/usuarios/models/usuario_response.dart';
import 'permisos_inquilino_sheet.dart';

class MisInquilinosScreen extends StatefulWidget {
  /// Si se provee, el padre gestiona el FAB y llama esta función al presionarlo.
  /// Si es null, la pantalla muestra su propio FAB interno.
  final void Function(VoidCallback agregarAction)? onFabRegistrado;

  const MisInquilinosScreen({super.key, this.onFabRegistrado});

  @override
  State<MisInquilinosScreen> createState() => _MisInquilinosScreenState();
}

class _MisInquilinosScreenState extends State<MisInquilinosScreen> {
  List<UsuarioResponse> _inquilinos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Registrar la acción del FAB en el padre si corresponde
    if (widget.onFabRegistrado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFabRegistrado!(_agregarInquilino);
      });
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await InquilinoService.listarInquilinos();
      if (!mounted) return;
      setState(() => _inquilinos = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregarInquilino() async {
    final nuevo = await showDialog<UsuarioResponse>(
      context: context,
      builder: (_) => const CrearInquilinoDialog(),
    );
    if (nuevo != null) {
      setState(() => _inquilinos.add(nuevo));
    }
  }

  Future<void> _abrirPermisos(UsuarioResponse inquilino) async {
    await PermisosInquilinoSheet.mostrar(context, inquilino);
  }

  Future<void> _eliminarInquilino(UsuarioResponse inquilino) async {
    final nombre = inquilino.nombre.trim().isNotEmpty
        ? inquilino.nombre.trim()
        : inquilino.email;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
          size: 40,
        ),
        title: const Text('Eliminar inquilino'),
        content: Text(
          '¿Seguro que deseas eliminar a $nombre?\n\n'
          'Se eliminarán su cuenta y todos sus accesos al conjunto. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await InquilinoService.eliminarInquilino(inquilino.id);
      setState(() => _inquilinos.removeWhere((i) => i.id == inquilino.id));
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Inquilino eliminado'),
        description: Text('$nombre fue eliminado de tu unidad.'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
        closeOnClick: true,
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Error al eliminar'),
        description: Text(e.toString().replaceFirst('Exception: ', '')),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
        closeOnClick: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis inquilinos',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Personas que comparten tu unidad',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_cargando)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_inquilinos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no tienes inquilinos',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Agrega personas que vivan en tu unidad',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final i = _inquilinos[index];
                      return _InquilinoCard(
                        inquilino: i,
                        onPermisos: () => _abrirPermisos(i),
                        onEliminar: () => _eliminarInquilino(i),
                      );
                    }, childCount: _inquilinos.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card del inquilino
// ─────────────────────────────────────────────────────────────────────────────

class _InquilinoCard extends StatelessWidget {
  final UsuarioResponse inquilino;
  final VoidCallback onPermisos;
  final VoidCallback onEliminar;

  const _InquilinoCard({
    required this.inquilino,
    required this.onPermisos,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = inquilino.nombre.trim().isNotEmpty
        ? inquilino.nombre.trim()
        : '?';
    final iniciales = TextoUtils.getIniciales(nombre);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior: avatar · nombre · menú ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    iniciales.isEmpty ? '?' : iniciales,
                    style: TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inquilino.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (inquilino.telefono != null &&
                          inquilino.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📞 ${inquilino.telefono}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Menú de acciones
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'permisos',
                      child: Row(
                        children: [
                          Icon(Icons.tune_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Gestionar permisos'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'permisos') onPermisos();
                    if (value == 'eliminar') onEliminar();
                  },
                ),
              ],
            ),

            // ── Botón rápido de permisos ──────────────────────────────────
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            InkWell(
              onTap: onPermisos,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gestionar permisos',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
