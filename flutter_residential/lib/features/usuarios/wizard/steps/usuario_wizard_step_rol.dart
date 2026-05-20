import 'package:flutter/material.dart';

// ─── Configuración de roles (pública para uso en resumen) ───────────────────

class RolConfig {
  final IconData icono;
  final String etiqueta;
  final String descripcion;
  final Color color;
  final bool requierePropiedad;

  const RolConfig({
    required this.icono,
    required this.etiqueta,
    required this.descripcion,
    required this.color,
    required this.requierePropiedad,
  });
}

const kRolesConfig = <String, RolConfig>{
  'PROPIETARIO': RolConfig(
    icono: Icons.home_outlined,
    etiqueta: 'Propietario',
    descripcion: 'Dueño de una unidad residencial',
    color: Colors.teal,
    requierePropiedad: true,
  ),
  'INQUILINO': RolConfig(
    icono: Icons.key_outlined,
    etiqueta: 'Inquilino',
    descripcion: 'Arrendatario de una unidad existente',
    color: Colors.blue,
    requierePropiedad: true,
  ),
  'TENANT_ADMIN': RolConfig(
    icono: Icons.admin_panel_settings_outlined,
    etiqueta: 'Administrador',
    descripcion: 'Gestión completa del conjunto',
    color: Colors.deepPurple,
    requierePropiedad: false,
  ),
  'VIGILANTE': RolConfig(
    icono: Icons.security_outlined,
    etiqueta: 'Vigilante',
    descripcion: 'Control de acceso y seguridad',
    color: Colors.orange,
    requierePropiedad: false,
  ),
  'PORTERO': RolConfig(
    icono: Icons.meeting_room_outlined,
    etiqueta: 'Portero',
    descripcion: 'Atención en portería',
    color: Colors.amber,
    requierePropiedad: false,
  ),
  'PISCINERO': RolConfig(
    icono: Icons.pool_outlined,
    etiqueta: 'Encargado de zonas comunes',
    descripcion: 'Mantenimiento de áreas compartidas',
    color: Colors.cyan,
    requierePropiedad: false,
  ),
  'CONTADOR': RolConfig(
    icono: Icons.calculate_outlined,
    etiqueta: 'Contador',
    descripcion: 'Gestión contable y financiera',
    color: Colors.indigo,
    requierePropiedad: false,
  ),
};

// ─── Grupos de roles ─────────────────────────────────────────────────────────

const _grupos = [
  (
    titulo: 'Residentes',
    subtitulo: 'Requieren asignación de unidad',
    icono: Icons.apartment_outlined,
    roles: ['PROPIETARIO', 'INQUILINO'],
  ),
  (
    titulo: 'Personal operativo',
    subtitulo: 'Staff del conjunto',
    icono: Icons.badge_outlined,
    roles: ['VIGILANTE', 'PORTERO', 'PISCINERO'],
  ),
  (
    titulo: 'Gestión',
    subtitulo: 'Administración y finanzas',
    icono: Icons.manage_accounts_outlined,
    roles: ['TENANT_ADMIN', 'CONTADOR'],
  ),
];

// ─── Widget principal ─────────────────────────────────────────────────────────

class UsuarioWizardStepRol extends StatelessWidget {
  final String? rolSeleccionado;
  final void Function(String) onRolCambiado;

  const UsuarioWizardStepRol({
    super.key,
    required this.rolSeleccionado,
    required this.onRolCambiado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final info = rolSeleccionado != null ? kRolesConfig[rolSeleccionado] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final grupo in _grupos) ...[
            _GrupoRoles(
              titulo: grupo.titulo,
              subtitulo: grupo.subtitulo,
              icono: grupo.icono,
              roles: grupo.roles,
              rolSeleccionado: rolSeleccionado,
              onRolCambiado: onRolCambiado,
            ),
            const SizedBox(height: 20),
          ],

          // Hint cuando se selecciona un rol que requiere propiedad
          if (info != null && info.requierePropiedad)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: info.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.home_work_outlined, size: 16, color: info.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se solicitará la unidad residencial más adelante.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: info.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Grupo de roles ───────────────────────────────────────────────────────────

class _GrupoRoles extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<String> roles;
  final String? rolSeleccionado;
  final void Function(String) onRolCambiado;

  const _GrupoRoles({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.roles,
    required this.rolSeleccionado,
    required this.onRolCambiado,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              titulo.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '· $subtitulo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...roles.map(
          (rol) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RolCard(
              rol: rol,
              config: kRolesConfig[rol]!,
              seleccionado: rolSeleccionado == rol,
              onTap: () => onRolCambiado(rol),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card de rol ──────────────────────────────────────────────────────────────

class _RolCard extends StatelessWidget {
  final String rol;
  final RolConfig config;
  final bool seleccionado;
  final VoidCallback onTap;

  const _RolCard({
    required this.rol,
    required this.config,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: seleccionado ? config.color.withValues(alpha: 0.07) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seleccionado ? config.color : cs.outlineVariant,
          width: seleccionado ? 2 : 1,
        ),
        boxShadow: seleccionado
            ? [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Ícono
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.color.withValues(
                        alpha: seleccionado ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(config.icono, color: config.color, size: 22),
                ),
                const SizedBox(width: 14),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.etiqueta,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: seleccionado ? config.color : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.descripcion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge "Unidad" si requiere propiedad
                if (config.requierePropiedad)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.amber.shade600.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Unidad',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                // Indicador de selección
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seleccionado ? config.color : Colors.transparent,
                    border: Border.all(
                      color:
                          seleccionado ? config.color : cs.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: seleccionado
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
