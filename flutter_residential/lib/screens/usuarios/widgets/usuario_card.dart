import 'package:flutter/material.dart';
import '../../../models/usuario_response.dart';

class UsuarioCard extends StatelessWidget {
  final UsuarioResponse usuario;
  final VoidCallback? onTap;

  const UsuarioCard({super.key, required this.usuario, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _colorRol(usuario.rol, theme),
          child: Text(
            usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          usuario.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _chip(context, _etiquetaRol(usuario.rol), _colorRol(usuario.rol, theme)),
                const SizedBox(width: 6),
                _chip(context, usuario.estado, _colorEstado(usuario.estado, theme)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _etiquetaRol(String rol) {
    switch (rol) {
      case 'SUPER_ADMIN': return 'Super Admin';
      case 'TENANT_ADMIN': return 'Admin';
      case 'RESIDENTE': return 'Residente';
      default: return rol;
    }
  }

  Color _colorRol(String rol, ThemeData theme) {
    switch (rol) {
      case 'SUPER_ADMIN': return Colors.deepPurple;
      case 'TENANT_ADMIN': return Colors.blue;
      default: return theme.colorScheme.primary;
    }
  }

  Color _colorEstado(String estado, ThemeData theme) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO': return Colors.green;
      case 'PENDIENTE': return Colors.orange;
      case 'RECHAZADO': return Colors.red;
      default: return theme.colorScheme.outline;
    }
  }
}
