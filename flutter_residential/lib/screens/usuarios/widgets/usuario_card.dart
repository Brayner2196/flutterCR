import 'package:flutter/material.dart';
import '../../../models/usuario_response.dart';
import '../usuario_editar_dialog.dart';

class UsuarioCard extends StatelessWidget {
  final UsuarioResponse usuario;
  final VoidCallback? onTap;

  const UsuarioCard({super.key, required this.usuario, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rolColor = _colorRol(usuario.rol, theme);
    final estadoColor = _colorEstado(usuario.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: avatar · nombre · menú ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar rectangular con iniciales
                  Container(
                    width: 52,
                    height: 58,
                    decoration: BoxDecoration(
                      color: rolColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _iniciales(usuario.nombre),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: rolColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre + ubicación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                usuario.nombre,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (usuario.rol == 'TENANT_ADMIN') ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  size: 16, color: Colors.amber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _ubicacion(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Menú tres puntos
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ]),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'editar') {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              UsuarioEditarDialog(usuario: usuario),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),

              // ── Fila inferior: rol · badge estado ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _etiquetaRol(usuario.rol),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: rolColor,
                        ),
                      ),
                    ],
                  ),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      usuario.estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: estadoColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  String _ubicacion() {
    final partes = <String>[];
    if (usuario.torre != null && usuario.torre!.isNotEmpty) {
      partes.add(usuario.torre!);
    }
    if (usuario.apto != null && usuario.apto!.isNotEmpty) {
      partes.add('Apto ${usuario.apto}');
    }
    return partes.isNotEmpty ? partes.join(' • ') : usuario.email;
  }

  String _etiquetaRol(String rol) {
    switch (rol) {
      case 'TENANT_ADMIN': return 'Administrador';
      case 'RESIDENTE': return 'Residente';
      case 'PISCINERO': return 'Piscinero';
      case 'VIGILANTE': return 'Vigilante';
      case 'PORTERO': return 'Portero';
      default: return rol;
    }
  }

  Color _colorRol(String rol, ThemeData theme) {
    switch (rol) {
      case 'TENANT_ADMIN': return const Color(0xFF2563EB);
      case 'RESIDENTE': return const Color(0xFF16A34A);
      case 'PISCINERO': return const Color(0xFF0891B2);
      case 'VIGILANTE': return const Color(0xFF6B7280);
      case 'PORTERO': return const Color(0xFF7C3AED);
      default: return theme.colorScheme.primary;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO': return const Color(0xFF2563EB);
      case 'PENDIENTE': return const Color(0xFFF97316);
      case 'RECHAZADO':
      case 'INACTIVO': return const Color(0xFFDC2626);
      default: return const Color(0xFF6B7280);
    }
  }
}
