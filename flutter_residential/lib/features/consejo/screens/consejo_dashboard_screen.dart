import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../anuncios/screens/admin/admin_anuncios_screen.dart';
import '../../votaciones/screens/admin/admin_votaciones_screen.dart';
import '../providers/consejo_provider.dart';
import 'consejo_actas_screen.dart';
import 'consejo_estadisticas_screen.dart';
import 'consejo_pqrs_screen.dart';
import 'consejo_directorio_screen.dart';

/// Pantalla principal del rol Consejero Comunal.
/// Accesible como tab condicional en ResidenteHomeScreen cuando esConsejero=true.
class ConsejoDashboardScreen extends StatefulWidget {
  const ConsejoDashboardScreen({super.key});

  @override
  State<ConsejoDashboardScreen> createState() => _ConsejoDashboardScreenState();
}

class _ConsejoDashboardScreenState extends State<ConsejoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsejoProvider>().cargarPqrs();
      context.read<ConsejoProvider>().cargarDirectorio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final consejo = context.watch<ConsejoProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cargoTexto = auth.cargoConsejo != null
        ? _cargoLegible(auth.cargoConsejo!)
        : 'Consejero';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ConsejoProvider>().cargarPqrs();
          await context.read<ConsejoProvider>().cargarDirectorio();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            // ── Banner de cargo ─────────────────────────────────────────────
            _BannerCargo(
              nombre: auth.nombre ?? 'Consejero',
              cargo: cargoTexto,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Sección de acceso rápido ────────────────────────────────────
            Text(
              'ACCESO RÁPIDO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickCard(
              label: 'PQRs del Conjunto',
              subtitulo: consejo.pqrsPendientes > 0
                  ? '${consejo.pqrsPendientes} radicadas pendientes'
                  : 'Ver todas las solicitudes',
              icono: Icons.support_agent_rounded,
              fg: AppColors.orange,
              bg: AppColors.bgOrange,
              badge: consejo.pqrsPendientes > 0 ? consejo.pqrsPendientes : null,
              onTap: () => _ir(context, const ConsejoPqrsScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickCard(
              label: 'Anuncios',
              subtitulo: 'Crear y publicar comunicados',
              icono: Icons.campaign_rounded,
              fg: AppColors.blue,
              bg: AppColors.bgBlue,
              onTap: () => _ir(context, const AdminAnunciosScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickCard(
              label: 'Votaciones',
              subtitulo: 'Crear y gestionar votaciones',
              icono: Icons.how_to_vote_rounded,
              fg: AppColors.green,
              bg: AppColors.bgGreen,
              onTap: () => _ir(context, const AdminVotacionesScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickCard(
              label: 'Actas de Reunión',
              subtitulo: auth.cargoConsejo == 'PRESIDENTE'
                  ? 'Grabar y transcribir con Whisper'
                  : 'Consultar actas del consejo',
              icono: Icons.mic_rounded,
              fg: AppColors.danger,
              bg: AppColors.dangerSoft,
              onTap: () => _ir(context, const ConsejoActasScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickCard(
              label: 'Directorio del Consejo',
              subtitulo: '${consejo.directorio.length} miembro${consejo.directorio.length != 1 ? 's' : ''} activos',
              icono: Icons.people_rounded,
              fg: AppColors.purple,
              bg: AppColors.bgPurple,
              onTap: () => _ir(context, const ConsejoDirectorioScreen()),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuickCard(
              label: 'Estadísticas',
              subtitulo: 'PQRs, anuncios y votaciones',
              icono: Icons.bar_chart_rounded,
              fg: AppColors.teal,
              bg: AppColors.bgTeal,
              onTap: () => _ir(context, const ConsejoEstadisticasScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _ir(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String _cargoLegible(String cargo) {
    if (cargo.isEmpty) return cargo;
    return cargo[0].toUpperCase() + cargo.substring(1).toLowerCase();
  }
}

// ─── Banner de cargo ──────────────────────────────────────────────────────────

class _BannerCargo extends StatelessWidget {
  final String nombre;
  final String cargo;
  final bool isDark;

  const _BannerCargo({
    required this.nombre,
    required this.cargo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceAltDark : AppColors.bgPurple;
    final fg = AppColors.purple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.gavel_rounded, color: fg, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo Comunal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                Text(
                  cargo,
                  style: TextStyle(
                    fontSize: 13,
                    color: fg.withValues(alpha: 0.75),
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

// ─── Quick access card ────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final String label;
  final String subtitulo;
  final IconData icono;
  final Color fg;
  final Color bg;
  final int? badge;
  final VoidCallback onTap;

  const _QuickCard({
    required this.label,
    required this.subtitulo,
    required this.icono,
    required this.fg,
    required this.bg,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tieneBadge = badge != null && badge! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icono, size: 22, color: fg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: fg, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            if (tieneBadge)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: fg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: fg.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}
