import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/widgets/theme_toggle_switch.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../usuarios/providers/app_provider.dart';
import '../../../shared/theme/app_theme.dart';

class PerfilResidenteScreen extends StatelessWidget {
  const PerfilResidenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propiedades = context.watch<PropiedadProvider>();
    final appProvider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nombre = auth.nombre ?? 'Usuario';
    final email = auth.email ?? '';
    final conjunto = auth.nombreConjunto ?? 'Conjunto Residencial';
    final propiedad =
        propiedades.propiedadActual?.pathTexto ?? 'Sin propiedad asignada';
    final iniciales = _iniciales(nombre);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + nombre ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        iniciales,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    nombre,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Info del conjunto ──
            _SeccionPerfil(
              titulo: 'Información de vivienda',
              items: [
                _ItemPerfil(
                  icono: Icons.apartment_rounded,
                  label: 'Conjunto',
                  valor: conjunto,
                ),
                _ItemPerfil(
                  icono: Icons.home_work_rounded,
                  label: 'Unidad',
                  valor: propiedad,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Preferencias ──
            _SeccionPerfil(
              titulo: 'Preferencias',
              items: [
                _ItemToggle(
                  icono: Icons.dark_mode_rounded,
                  label: 'Tema oscuro',
                  valor: appProvider.themeMode == ThemeMode.dark,
                  onChanged: appProvider.toggleTheme,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Sesión ──
            _SeccionPerfil(
              titulo: 'Sesión',
              items: [
                _ItemAccion(
                  icono: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  color: cs.error,
                  onTap: () => _confirmarLogout(context, auth),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Future<void> _confirmarLogout(
      BuildContext context, AuthProvider auth) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await auth.logout();
    }
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}

// ─── Sección agrupadora ──────────────────────────────────────────────────────

class _SeccionPerfil extends StatelessWidget {
  final String titulo;
  final List<Widget> items;

  const _SeccionPerfil({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            titulo.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: AppSpacing.md + 32 + AppSpacing.md,
                        endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Ítem de info ────────────────────────────────────────────────────────────

class _ItemPerfil extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _ItemPerfil({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Icon(icono, size: 20, color: cs.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                Text(valor,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ítem toggle ─────────────────────────────────────────────────────────────

class _ItemToggle extends StatelessWidget {
  final IconData icono;
  final String label;
  final bool valor;
  final VoidCallback onChanged;

  const _ItemToggle({
    required this.icono,
    required this.label,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ThemeToggleSwitch(
                  isDark: valor,
                  onToggle: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ítem acción ─────────────────────────────────────────────────────────────

class _ItemAccion extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ItemAccion({
    required this.icono,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final efectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icono, size: 20, color: efectiveColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: efectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: efectiveColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
