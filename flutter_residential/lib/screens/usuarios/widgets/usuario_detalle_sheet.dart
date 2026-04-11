import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/usuario_response.dart';
import '../../../providers/usuario_provider.dart';

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
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

                    if (mostrarAcciones) ...[
                      //const SizedBox(height: 24),
                      _BotonesAprobacion(usuario: usuario),
                    ],

                    const SizedBox(height: 24),

                    // Información
                    _seccion(theme, 'Información general', [
                      _fila(theme, 'Rol', _etiquetaRol(usuario.rol)),
                      _fila(theme, 'Estado', usuario.estado),
                      //_fila(theme, 'ID', '#${usuario.id}'),
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
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _etiquetaRol(String rol) {
    switch (rol) {
      case 'SUPER_ADMIN': return 'Super Admin';
      case 'TENANT_ADMIN': return 'Administrador';
      case 'RESIDENTE': return 'Residente';
      default: return rol;
    }
  }
}

class _BotonesAprobacion extends StatefulWidget {
  final UsuarioResponse usuario;
  const _BotonesAprobacion({required this.usuario});

  @override
  State<_BotonesAprobacion> createState() => _BotonesAprobacionState();
}

class _BotonesAprobacionState extends State<_BotonesAprobacion> {
  bool _cargando = false;

  Future<void> _accion(Future<void> Function() fn) async {
    setState(() => _cargando = true);
    try {
      await fn();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
                : () => _accion(() => provider.rechazar(widget.usuario.id)),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _cargando
                ? null
                : () => _accion(() => provider.aprobar(widget.usuario.id)),
            icon: _cargando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: const Text('Aprobar'),
          ),
        ),
      ],
    );
  }
}
