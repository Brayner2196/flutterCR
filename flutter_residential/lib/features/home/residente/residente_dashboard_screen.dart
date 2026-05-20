import 'package:flutter/material.dart';
import 'package:flutter_residential/features/home/residente/widgets/carousel/carousel_info_relevante_residente.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inquilinos/providers/inquilino_permisos_provider.dart';
import '../../usuarios/providers/residente_estadisticas_provider.dart';
import '../../anuncios/providers/anuncio_provider.dart';
import '../../pqr/providers/pqr_provider.dart';
import '../../votaciones/providers/votacion_provider.dart';
import '../../pagos/screens/residente/estado_cuenta_screen.dart';
import '../../reservas/screens/residente/mis_reservas_screen.dart';
import '../../pqr/screens/residente/mis_pqrs_screen.dart';
import '../../anuncios/screens/residente/mis_anuncios_screen.dart';
import '../../votaciones/screens/residente/mis_votaciones_screen.dart';
import '../../marketplace/screens/residente/marketplace_screen.dart';
import 'widgets/quick_access_card.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class ResidenteDashboardScreen extends StatefulWidget {
  final void Function(int index) onNavegar;

  const ResidenteDashboardScreen({super.key, required this.onNavegar});

  @override
  State<ResidenteDashboardScreen> createState() =>
      _ResidenteDashboardScreenState();
}

class _ResidenteDashboardScreenState extends State<ResidenteDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final permisos = context.read<InquilinoPermisosProvider>();

      // Estadísticas financieras solo si el usuario tiene acceso
      if (auth.isPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
        context.read<ResidenteEstadisticasProvider>().cargar();
      }
      // Datos para badges: solo si tiene el permiso correspondiente
      if (auth.isPropietario || permisos.tienePermiso('ANUNCIOS')) {
        context.read<AnuncioProvider>().cargarResidente();
      }
      if (auth.isPropietario || permisos.tienePermiso('PQRS')) {
        context.read<PqrProvider>().cargarMisPqrs();
      }
      if (auth.isPropietario || permisos.tienePermiso('VOTAR')) {
        context.read<VotacionProvider>().cargarResidente();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final permisos = context.watch<InquilinoPermisosProvider>();
    final stats = context.watch<ResidenteEstadisticasProvider>();
    final anuncios = context.watch<AnuncioProvider>();
    final pqrs = context.watch<PqrProvider>();
    final votaciones = context.watch<VotacionProvider>();

    final esPropietario = auth.isPropietario;

    return RefreshIndicator(
      onRefresh: () async {
        if (esPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
          await stats.refrescar();
        }
        if (esPropietario || permisos.tienePermiso('ANUNCIOS')) {
          await anuncios.cargarResidente();
        }
        if (esPropietario || permisos.tienePermiso('PQRS')) {
          await pqrs.cargarMisPqrs();
        }
        if (esPropietario || permisos.tienePermiso('VOTAR')) {
          await votaciones.cargarResidente();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselInfoRelevanteResidente(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildAccesos(
              context: context,
              esPropietario: esPropietario,
              permisos: permisos,
              anuncios: anuncios,
              pqrs: pqrs,
              votaciones: votaciones,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─── Accesos rápidos ──────────────────────────────────────────────────────

  Widget _buildAccesos({
    required BuildContext context,
    required bool esPropietario,
    required InquilinoPermisosProvider permisos,
    required AnuncioProvider anuncios,
    required PqrProvider pqrs,
    required VotacionProvider votaciones,
  }) {
    /// Devuelve true si el módulo es visible para el usuario actual.
    bool puede(String permiso) => esPropietario || permisos.tienePermiso(permiso);

    final cards = <Widget>[];

    // Estado de Cuenta
    if (puede('ESTADO_CUENTA')) {
      cards.add(QuickAccessCard(
        label: 'Estado de Cuenta',
        subtitulo: 'Ver cobros y deuda',
        icono: Icons.account_balance_wallet_outlined,
        fg: AppColors.blue,
        bg: AppColors.bgBlue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
        ),
      ));
    }

    // Reservas
    if (puede('RESERVAS')) {
      cards.add(QuickAccessCard(
        label: 'Reservas',
        subtitulo: 'Áreas comunes',
        icono: Icons.event_outlined,
        fg: AppColors.orange,
        bg: AppColors.bgOrange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisReservasScreen()),
        ),
      ));
    }

    // PQRs
    if (puede('PQRS')) {
      cards.add(QuickAccessCard(
        label: 'PQRs',
        subtitulo: pqrs.cantidadPendientes > 0
            ? '${pqrs.cantidadPendientes} pendiente${pqrs.cantidadPendientes == 1 ? '' : 's'}'
            : 'Sin pendientes',
        icono: Icons.support_agent_outlined,
        fg: AppColors.purple,
        bg: AppColors.bgPurple,
        badge: pqrs.cantidadPendientes > 0 ? pqrs.cantidadPendientes : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
        ),
      ));
    }

    // Anuncios
    if (puede('ANUNCIOS')) {
      cards.add(QuickAccessCard(
        label: 'Anuncios',
        subtitulo: anuncios.noVistos > 0
            ? '${anuncios.noVistos} nuevo${anuncios.noVistos == 1 ? '' : 's'}'
            : 'Sin novedades',
        icono: Icons.campaign_outlined,
        fg: AppColors.yellow,
        bg: AppColors.bgYellow,
        badge: anuncios.noVistos > 0 ? anuncios.noVistos : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisAnunciosScreen()),
        ),
      ));
    }

    // Votaciones
    if (puede('VOTAR')) {
      cards.add(QuickAccessCard(
        label: 'Votaciones',
        subtitulo: votaciones.pendientesDeVotar > 0
            ? '${votaciones.pendientesDeVotar} ${votaciones.pendientesDeVotar == 1 ? 'votación abierta' : 'votaciones abiertas'}'
            : 'Sin votaciones activas',
        icono: Icons.how_to_vote_outlined,
        fg: AppColors.green,
        bg: AppColors.bgGreen,
        badge: votaciones.pendientesDeVotar > 0
            ? votaciones.pendientesDeVotar
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisVotacionesScreen()),
        ),
      ));
    }

    // Marketplace
    if (puede('MARKETPLACE')) {
      cards.add(QuickAccessCard(
        label: 'Marketplace',
        subtitulo: 'Compra y vende en el conjunto',
        icono: Icons.storefront_outlined,
        fg: AppColors.teal,
        bg: AppColors.bgTeal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
        ),
      ));
    }

    // Mi Propiedad — siempre visible
    cards.add(QuickAccessCard(
      label: 'Mi Propiedad',
      subtitulo: 'Ver detalles de tu unidad',
      icono: Icons.home_work_outlined,
      fg: AppColors.blue,
      bg: AppColors.bgBlue,
      onTap: () => widget.onNavegar(2),
    ));

    if (cards.isEmpty) {
      return const _SinAccesosWidget();
    }

    return Column(
      children: cards
          .expand((c) => [c, const SizedBox(height: AppSpacing.sm)])
          .toList()
        ..removeLast(), // quitar el último SizedBox extra
    );
  }
}

/// Mostrado cuando el inquilino no tiene ningún permiso otorgado.
class _SinAccesosWidget extends StatelessWidget {
  const _SinAccesosWidget();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Sin accesos habilitados',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'El propietario aún no te ha otorgado\npermisos sobre módulos del conjunto.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
