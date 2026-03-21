import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int index) onNavegar;

  const DashboardScreen({super.key, required this.onNavegar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.email ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _etiquetaRol(auth),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Accesos rápidos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: _accesosPorRol(auth, theme),
          ),
        ],
      ),
    );
  }

  String _etiquetaRol(AuthProvider auth) {
    if (auth.isSuperAdmin) return 'Super Administrador';
    if (auth.isAdmin) return 'Administrador';
    return 'Residente';
  }

  List<Widget> _accesosPorRol(AuthProvider auth, ThemeData theme) {
    final items = <_Acceso>[];

    if (auth.isSuperAdmin || auth.isAdmin) {
      items.add(_Acceso('Usuarios', Icons.people_outline, Colors.blue, () => onNavegar(1)));
    }
    if (auth.isAdmin) {
      items.add(_Acceso('Propietarios', Icons.person_pin_outlined, Colors.orange, () => onNavegar(2)));
      items.add(_Acceso('Propiedades', Icons.home_outlined, Colors.green, () => onNavegar(3)));
    }
    if (auth.isResidente) {
      items.add(_Acceso('Mi propiedad', Icons.home_outlined, Colors.green, () {}));
    }

    return items.map((a) => _tarjeta(a, theme)).toList();
  }

  Widget _tarjeta(_Acceso a, ThemeData theme) {
    return InkWell(
      onTap: a.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: a.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: a.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(a.icono, size: 36, color: a.color),
            const SizedBox(height: 8),
            Text(
              a.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: a.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Acceso {
  final String label;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  _Acceso(this.label, this.icono, this.color, this.onTap);
}
