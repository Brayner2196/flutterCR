import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import 'admin_configurar_cuotas_screen.dart';
import 'admin_configurar_mora_screen.dart';
import 'admin_pasarelas_screen.dart';

/// Centro de configuración del módulo de cobros.
///
/// Agrupa lo que antes estaba disperso en iconos sueltos del AppBar:
/// cuotas, mora y pasarelas de pago.
class CobrosConfigScreen extends StatelessWidget {
  const CobrosConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de cobros')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _OpcionConfig(
            icono: Icons.tune,
            color: AppColors.blue,
            titulo: 'Cuotas',
            descripcion: 'Valor de administración y conceptos por propiedad',
            destino: const AdminConfigurarCuotasScreen(),
          ),
          _OpcionConfig(
            icono: Icons.gavel_outlined,
            color: AppColors.warning,
            titulo: 'Mora',
            descripcion: 'Reglas de interés y recargos por pago tardío',
            destino: const AdminConfigurarMoraScreen(),
          ),
          _OpcionConfig(
            icono: Icons.account_balance_wallet_outlined,
            color: AppColors.green,
            titulo: 'Pasarelas de pago',
            descripcion: 'Medios de pago en línea disponibles',
            destino: const AdminPasarelasScreen(),
          ),
        ],
      ),
    );
  }
}

class _OpcionConfig extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;
  final Widget destino;

  const _OpcionConfig({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icono, color: color, size: 22),
      ),
      title: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(descripcion,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destino),
      ),
    );
  }
}
