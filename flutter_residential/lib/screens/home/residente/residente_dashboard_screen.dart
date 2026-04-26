import 'package:flutter/material.dart';
import 'package:flutter_residential/screens/home/residente/pagos/estado_cuenta_screen.dart';
import 'package:flutter_residential/screens/home/residente/pagos/mis_pagos_screen.dart';
import 'package:flutter_residential/screens/home/residente/widgets/banner_bienvenida.dart';
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
          BannerBienvenidaResidente(nombreUser: auth.nombre ?? 'Usuario'),
          const SizedBox(height: 24),
          Text(
            'Accesos rápidos',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
              _tarjeta(
                theme: theme,
                label: 'Estado de Cuenta',
                icono: Icons.account_balance_wallet_outlined,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EstadoCuentaScreen()),
                ),
              ),
              _tarjeta(
                theme: theme,
                label: 'Mis Pagos',
                icono: Icons.receipt_long_outlined,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisPagosScreen()),
                ),
              ),
            ],
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
