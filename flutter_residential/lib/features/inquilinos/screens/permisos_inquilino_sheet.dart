import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_response.dart';
import '../services/inquilino_service.dart';
import '../../../shared/utils/texto_utils.dart';

/// Mapa de permiso → etiqueta + icono para mostrar en la UI.
const _permisosInfo = {
  'ESTADO_CUENTA': (label: 'Estado de cuenta', sublabel: 'Ver pagos, cuotas y estado financiero de su propiedad', icon: Icons.account_balance_wallet_outlined),
  'ANUNCIOS': (label: 'Anuncios', sublabel: 'Ver los anuncios del conjunto', icon: Icons.campaign_outlined),
  'VOTAR': (label: 'Votar', sublabel: 'Participar en votaciones del conjunto', icon: Icons.how_to_vote_outlined),
  'PQRS': (label: 'PQR', sublabel: 'Presentar peticiones, quejas o reclamos', icon: Icons.support_agent_outlined),
  'RESERVAS': (label: 'Reservas', sublabel: 'Reservar zonas comunes', icon: Icons.event_available_outlined),
  'MARKETPLACE': (label: 'Marketplace', sublabel: 'Publicar y comprar en el marketplace', icon: Icons.storefront_outlined),
};

class PermisosInquilinoSheet extends StatefulWidget {
  final UsuarioResponse inquilino;

  const PermisosInquilinoSheet({super.key, required this.inquilino});

  /// Abre el sheet y retorna true si hubo cambios.
  static Future<bool> mostrar(BuildContext context, UsuarioResponse inquilino) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PermisosInquilinoSheet(inquilino: inquilino),
    );
    return result ?? false;
  }

  @override
  State<PermisosInquilinoSheet> createState() => _PermisosInquilinoSheetState();
}

class _PermisosInquilinoSheetState extends State<PermisosInquilinoSheet> {
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  late Set<String> _permisos;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    try {
      final lista = await InquilinoService.listarPermisos(widget.inquilino.id);
      setState(() {
        _permisos = lista.toSet();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await InquilinoService.actualizarPermisos(
          widget.inquilino.id, _permisos.toList());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = widget.inquilino.nombre.trim().isNotEmpty
        ? widget.inquilino.nombre.trim()
        : widget.inquilino.email;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Cabecera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    TextoUtils.getIniciales(nombre),
                    style: TextStyle(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Permisos del inquilino',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // Contenido
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: theme.colorScheme.error),
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Text(
                              'Activa o desactiva los permisos que quieres conceder a este inquilino.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ..._permisosInfo.entries.map((entry) {
                            final key = entry.key;
                            final info = entry.value;
                            return SwitchListTile(
                              secondary: Icon(info.icon,
                                  color: _permisos.contains(key)
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant),
                              title: Text(info.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(info.sublabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  )),
                              value: _permisos.contains(key),
                              onChanged: _guardando
                                  ? null
                                  : (val) => setState(() {
                                        if (val) {
                                          _permisos.add(key);
                                        } else {
                                          _permisos.remove(key);
                                        }
                                      }),
                            );
                          }),
                        ],
                      ),
          ),

          // Botón guardar
          if (!_cargando && _error == null)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label:
                      Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
