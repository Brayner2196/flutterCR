import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ResidenteDashboardScreen extends StatelessWidget {
  final void Function(int index) onNavegar;

  const ResidenteDashboardScreen({super.key, required this.onNavegar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bannerBienvenida(theme, auth.email ?? ''),
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
            children: [
              _tarjeta(
                theme: theme,
                label: 'Mi Propiedad',
                icono: Icons.home_work_outlined,
                color: Colors.green,
                onTap: () => onNavegar(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerBienvenida(ThemeData theme, String email) {
    return Container(
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
            email,
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
              'Residente',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta({
    required ThemeData theme,
    required String label,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
