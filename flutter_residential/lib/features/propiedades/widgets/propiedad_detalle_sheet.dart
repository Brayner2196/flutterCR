import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/propiedad_admin.dart';
import '../providers/gestion_propiedades_provider.dart';
import 'asignar_residente_dialog.dart';

/// Hoja de detalle de una propiedad. Se alimenta en vivo del provider por id,
/// de modo que refleja los cambios (estado, residentes) sin cerrarse.
class PropiedadDetalleSheet extends StatelessWidget {
  final int propiedadId;

  const PropiedadDetalleSheet({super.key, required this.propiedadId});

  static Future<void> mostrar(BuildContext context, int propiedadId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropiedadDetalleSheet(propiedadId: propiedadId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer<GestionPropiedadesProvider>(
            builder: (context, provider, __) {
              final prop = provider.porId(propiedadId);
              if (prop == null) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Propiedad no disponible')),
                );
              }
              return _Contenido(prop: prop, controller: controller);
            },
          ),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  final PropiedadAdmin prop;
  final ScrollController controller;

  const _Contenido({required this.prop, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final estadoColor = EstadoPropiedad.color(prop.estado);
    final iconColor =
        prop.esParqueadero ? const Color(0xFF7C3AED) : cs.primary;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              // ── Encabezado ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    prop.esParqueadero
                        ? Icons.local_parking_outlined
                        : Icons.home_work_outlined,
                    color: iconColor,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  prop.pathTexto,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  prop.nombreTipo,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 20),

              // ── Estado + acción cambiar ─────────────────────────────────
              _seccion(theme, 'Estado', [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(EstadoPropiedad.icono(prop.estado),
                              size: 18, color: estadoColor),
                          const SizedBox(width: 8),
                          Text(
                            EstadoPropiedad.etiqueta(prop.estado),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: estadoColor,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _cambiarEstado(context),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Cambiar'),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Información ──────────────────────────────────────────────
              _seccion(theme, 'Información', [
                _fila(theme, 'Tipo', prop.nombreTipo),
                _fila(theme, 'Identificador', prop.identificador),
                _fila(theme, 'Facturable', prop.esFacturable ? 'Sí' : 'No'),
                _fila(theme, 'Parqueadero', prop.esParqueadero ? 'Sí' : 'No'),
              ]),

              const SizedBox(height: 16),

              // ── Residentes ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Residentes (${prop.totalResidentes})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    tooltip: 'Asignar residente',
                    onPressed: () => _asignarResidente(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (prop.residentes.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 40, color: cs.outline),
                        const SizedBox(height: 8),
                        Text(
                          'Sin residentes asignados',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: prop.residentes
                        .map((r) => _ResidenteTile(prop: prop, residente: r))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ── Acciones ──────────────────────────────────────────────────────────────
  Future<void> _cambiarEstado(BuildContext context) async {
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => _CambiarEstadoDialog(actual: prop.estado),
    );
    if (nuevo == null || nuevo == prop.estado) return;
    if (!context.mounted) return;
    try {
      await context
          .read<GestionPropiedadesProvider>()
          .cambiarEstado(prop.id, nuevo);
    } catch (e) {
      if (context.mounted) _error(context, e);
    }
  }

  Future<void> _asignarResidente(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AsignarResidenteDialog(propiedad: prop),
    );
  }

  static void _error(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  // ── Helpers de layout ───────────────────────────────────────────────────────
  Widget _seccion(ThemeData theme, String titulo, List<Widget> hijos) {
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
            color:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: hijos),
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
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de un residente asignado ─────────────────────────────────────────────
class _ResidenteTile extends StatelessWidget {
  final PropiedadAdmin prop;
  final ResidenteResumen residente;

  const _ResidenteTile({required this.prop, required this.residente});

  Future<void> _marcarPrincipal(BuildContext context) async {
    try {
      await context
          .read<GestionPropiedadesProvider>()
          .marcarPrincipal(prop.id, residente.usuarioId);
    } catch (e) {
      if (context.mounted) _Contenido._error(context, e);
    }
  }

  Future<void> _quitar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar residente'),
        content: Text(
            '¿Quitar a ${residente.nombre} de ${prop.titulo}?'),
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
    if (ok != true || !context.mounted) return;
    try {
      await context
          .read<GestionPropiedadesProvider>()
          .quitarResidente(prop.id, residente.usuarioId);
    } catch (e) {
      if (context.mounted) _Contenido._error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(
              residente.nombre.isNotEmpty
                  ? residente.nombre[0].toUpperCase()
                  : '?',
              style:
                  TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        residente.nombre,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (residente.esPrincipal) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 15, color: Colors.amber),
                    ],
                  ],
                ),
                Text(
                  residente.email,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            onSelected: (a) {
              if (a == 'principal') _marcarPrincipal(context);
              if (a == 'quitar') _quitar(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'principal',
                enabled: !residente.esPrincipal,
                child: const Row(children: [
                  Icon(Icons.star_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Marcar como principal'),
                ]),
              ),
              const PopupMenuItem(
                value: 'quitar',
                child: Row(children: [
                  Icon(Icons.remove_circle_outline,
                      size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Quitar', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Diálogo cambiar estado ────────────────────────────────────────────────────
class _CambiarEstadoDialog extends StatefulWidget {
  final String actual;
  const _CambiarEstadoDialog({required this.actual});

  @override
  State<_CambiarEstadoDialog> createState() => _CambiarEstadoDialogState();
}

class _CambiarEstadoDialogState extends State<_CambiarEstadoDialog> {
  late String _seleccionado = widget.actual;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar estado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: EstadoPropiedad.todos.map((e) {
          final sel = e == _seleccionado;
          final color = EstadoPropiedad.color(e);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(EstadoPropiedad.icono(e), color: color),
            title: Text(EstadoPropiedad.etiqueta(e)),
            trailing: sel ? Icon(Icons.check_circle, color: color) : null,
            selected: sel,
            onTap: () => setState(() => _seleccionado = e),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _seleccionado),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
