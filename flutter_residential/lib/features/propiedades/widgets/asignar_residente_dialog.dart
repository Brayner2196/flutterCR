import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../usuarios/models/usuario_response.dart';
import '../../usuarios/providers/usuario_provider.dart';
import '../models/propiedad_admin.dart';
import '../providers/gestion_propiedades_provider.dart';

/// Diálogo para asignar un residente existente a una propiedad.
/// Muestra los usuarios con rol Propietario/Inquilino que aún no están
/// asignados a la unidad, con búsqueda por nombre o correo.
class AsignarResidenteDialog extends StatefulWidget {
  final PropiedadAdmin propiedad;

  const AsignarResidenteDialog({super.key, required this.propiedad});

  @override
  State<AsignarResidenteDialog> createState() => _AsignarResidenteDialogState();
}

class _AsignarResidenteDialogState extends State<AsignarResidenteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _busqueda = '';
  bool _asignando = false;
  int? _asignandoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UsuarioProvider>();
      if (provider.usuarios.isEmpty) provider.cargarTodos();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UsuarioResponse> _candidatos(UsuarioProvider provider) {
    final asignados =
        widget.propiedad.residentes.map((r) => r.usuarioId).toSet();
    return provider.usuarios.where((u) {
      final esResidente = u.rol == 'PROPIETARIO' || u.rol == 'INQUILINO';
      if (!esResidente || asignados.contains(u.id)) return false;
      if (_busqueda.isEmpty) return true;
      return u.nombre.toLowerCase().contains(_busqueda) ||
          u.email.toLowerCase().contains(_busqueda);
    }).toList();
  }

  Future<void> _asignar(UsuarioResponse usuario) async {
    setState(() {
      _asignando = true;
      _asignandoId = usuario.id;
    });
    try {
      await context
          .read<GestionPropiedadesProvider>()
          .asignarResidente(widget.propiedad.id, usuario.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _asignando = false;
          _asignandoId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Asignar residente a ${widget.propiedad.titulo}'),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _busqueda = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<UsuarioProvider>(
                builder: (_, provider, __) {
                  if (provider.loading && provider.usuarios.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lista = _candidatos(provider);
                  if (lista.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 48,
                              color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 8),
                          Text(
                            _busqueda.isEmpty
                                ? 'No hay residentes disponibles para asignar'
                                : 'Sin coincidencias',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = lista[i];
                      final cargando = _asignando && _asignandoId == u.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            u.nombre.isNotEmpty
                                ? u.nombre[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u.nombre,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${u.rol == 'PROPIETARIO' ? 'Propietario' : 'Inquilino'} · ${u.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap:
                            _asignando ? null : () => _asignar(u),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
