import 'package:flutter/material.dart';
import 'package:flutter_residential/features/configuracion/screens/config_conjunto_screen.dart';
import 'package:flutter_residential/features/configuracion/screens/config_tipos_propiedad_screen.dart';
import 'package:flutter_residential/features/configuracion/screens/config_zonas_screen.dart';
import 'package:flutter_residential/features/configuracion/widgets/config_section_tile.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_cobro_especial_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_configurar_cuotas_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_configurar_mora_screen.dart';
import 'package:flutter_residential/features/pagos/screens/admin/admin_pasarelas_screen.dart';
import 'package:flutter_residential/features/plan_pago/screens/admin/admin_config_plan_pago_screen.dart';
import 'package:flutter_residential/features/presupuesto/screens/admin/admin_presupuestos_screen.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Configuración'),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Conjunto ──────────────────────────────────────────────
                _Grupo(
                  titulo: 'Conjunto',
                  children: [
                    ConfigSectionTile(
                      icono: Icons.apartment_outlined,
                      color: Colors.deepPurple,
                      titulo: 'Información del conjunto',
                      subtitulo: 'Nombre, dirección y código de acceso',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConfigConjuntoScreen(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Financiero ────────────────────────────────────────────
                _Grupo(
                  titulo: 'Financiero',
                  children: [
                    ConfigSectionTile(
                      icono: Icons.receipt_long_outlined,
                      color: Colors.teal,
                      titulo: 'Cuotas de administración',
                      subtitulo: 'Montos, periodicidad y rangos por unidad',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminConfigurarCuotasScreen(),
                      )),
                    ),
                    const SizedBox(height: 10),
                    ConfigSectionTile(
                      icono: Icons.attach_money_outlined,
                      color: Colors.indigo,
                      titulo: 'Cobro especial',
                      subtitulo: 'Generar cobros únicos por concepto, monto y unidad',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminCobroEspecialScreen(),
                      )),
                    ),
                    const SizedBox(height: 10),
                    ConfigSectionTile(
                      icono: Icons.warning_amber_outlined,
                      color: Colors.orange,
                      titulo: 'Mora',
                      subtitulo: 'Tipo de cálculo, porcentaje y días de gracia',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminConfigurarMoraScreen(),
                      )),
                    ),
                    const SizedBox(height: 10),
                    ConfigSectionTile(
                      icono: Icons.calendar_month_outlined,
                      color: Colors.deepOrange,
                      titulo: 'Plan de pago',
                      subtitulo: 'Fraccionar deuda en cuotas — reglas y aprobación',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminConfigPlanPagoScreen(),
                      )),
                    ),
                    const SizedBox(height: 10),
                    ConfigSectionTile(
                      icono: Icons.account_balance_outlined,
                      color: Colors.green,
                      titulo: 'Presupuesto',
                      subtitulo: 'Presupuesto anual por categorías y registro de gastos',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminPresupuestosScreen(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Propiedades ───────────────────────────────────────────
                _Grupo(
                  titulo: 'Propiedades',
                  children: [
                    ConfigSectionTile(
                      icono: Icons.account_tree_outlined,
                      color: Colors.blue,
                      titulo: 'Tipos de propiedad',
                      subtitulo: 'Jerarquía del conjunto (Torre → Piso → Apto)',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConfigTiposPropiedadScreen(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Pagos ─────────────────────────────────────────────────
                _Grupo(
                  titulo: 'Pagos',
                  children: [
                    ConfigSectionTile(
                      icono: Icons.payments_outlined,
                      color: Colors.blue,
                      titulo: 'Pasarelas de pago',
                      subtitulo: 'MercadoPago, Wompi, Bold — claves y activación',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminPasarelasScreen(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Zonas comunes ─────────────────────────────────────────
                _Grupo(
                  titulo: 'Zonas comunes',
                  children: [
                    ConfigSectionTile(
                      icono: Icons.pool_outlined,
                      color: Colors.cyan,
                      titulo: 'Gestión de zonas',
                      subtitulo: 'Horarios, capacidad, reglas y excepciones',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConfigZonasScreen(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info de versión/app
                Center(
                  child: Text(
                    'Configuración del conjunto residencial',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grupo con encabezado ──────────────────────────────────────────────────────

class _Grupo extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Grupo({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
