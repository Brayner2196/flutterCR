import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
import '../../documentos/screens/residente/documentos_residente_screen.dart';
import '../../votaciones/screens/residente/mis_votaciones_screen.dart';
import '../../marketplace/screens/residente/marketplace_screen.dart';
import '../../visitas/screens/mis_visitas_screen.dart';
import '../../paquetes_residente/screens/mis_paquetes_screen.dart';
import '../../plan_pago/screens/residente/residente_mi_plan_screen.dart';
import '../../plan_pago/providers/plan_pago_provider.dart';
import '../../presupuesto/screens/residente/residente_presupuesto_screen.dart';
import '../../presupuesto/providers/presupuesto_provider.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../parqueaderos/screens/residente/mis_parqueaderos_residente_screen.dart';
import 'widgets/quick_access_card.dart';
import 'widgets/carousel/deuda_resumen_widget.dart';
import 'widgets/feed/activity_feed_widget.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class ResidenteDashboardScreen extends StatefulWidget {
  final void Function(int index) onNavegar;

  const ResidenteDashboardScreen({super.key, required this.onNavegar});

  @override
  State<ResidenteDashboardScreen> createState() =>
      _ResidenteDashboardScreenState();
}

class _ResidenteDashboardScreenState extends State<ResidenteDashboardScreen> {
  bool _estadisticasCargadas = false;
  bool _esGridView = false;

  static const _kGridViewPref = 'dashboard_grid_view';

  @override
  void initState() {
    super.initState();
    _cargarPreferenciaGrid();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final permisos = context.read<InquilinoPermisosProvider>();
      final propProvider = context.read<PropiedadProvider>();

      if (auth.isPropietario || permisos.tienePermiso('ANUNCIOS')) {
        context.read<AnuncioProvider>().cargarResidente();
      }
      if (auth.isPropietario || permisos.tienePermiso('PQRS')) {
        context.read<PqrProvider>().cargarMisPqrs();
      }
      if (auth.isPropietario || permisos.tienePermiso('VOTAR')) {
        context.read<VotacionProvider>().cargarResidente();
      }
      if (auth.isPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
        context.read<PlanPagoProvider>().cargarConfigResidente();
        context.read<PlanPagoProvider>().cargarMisPlanes();
      }
      context.read<PresupuestoProvider>().cargarActivo();

      final pid = propProvider.propiedadActual?.propiedadId;
      if (pid != null) {
        _cargarEstadisticas(pid);
      } else {
        propProvider.addListener(_onPropiedadLista);
      }
    });
  }

  Future<void> _cargarPreferenciaGrid() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _esGridView = prefs.getBool(_kGridViewPref) ?? false);
    }
  }

  Future<void> _toggleGridView() async {
    final newValue = !_esGridView;
    setState(() => _esGridView = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGridViewPref, newValue);
  }

  void _onPropiedadLista() {
    if (_estadisticasCargadas || !mounted) return;
    final pid = context.read<PropiedadProvider>().propiedadActual?.propiedadId;
    if (pid == null) return;
    _estadisticasCargadas = true;
    context.read<PropiedadProvider>().removeListener(_onPropiedadLista);
    _cargarEstadisticas(pid);
  }

  void _cargarEstadisticas(int propiedadId) {
    final auth = context.read<AuthProvider>();
    final permisos = context.read<InquilinoPermisosProvider>();
    if (auth.isPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
      context.read<ResidenteEstadisticasProvider>()
          .cargar(propiedadId: propiedadId);
    }
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  Widget _buildErrorDeuda(BuildContext context, ResidenteEstadisticasProvider stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stats.error ?? 'Error al cargar datos financieros',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => stats.refrescar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<PropiedadProvider>().removeListener(_onPropiedadLista);
    super.dispose();
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
    context.watch<PresupuestoProvider>();

    final esPropietario = auth.isPropietario;
    final propiedadProvider = context.watch<PropiedadProvider>();
    final esParqueadero = propiedadProvider.propiedadActualEsParqueadero;
    final cs = theme.colorScheme;

    final tengoPermiso = esPropietario || permisos.tienePermiso('ESTADO_CUENTA');
    final ultimoPago = stats.estadisticas?.ultimoPago;
    final hayActividad = ultimoPago != null ||
        anuncios.anuncios.any((a) => !a.vistoPorMi) ||
        pqrs.pqrs.any((p) => p.esPendiente || p.esEnProceso) ||
        votaciones.votaciones.any((v) => v.estado == 'ABIERTA' && !v.yaVote);

    return RefreshIndicator(
      onRefresh: () async {
        final pid = context.read<PropiedadProvider>().propiedadActual?.propiedadId;
        if (esPropietario || permisos.tienePermiso('ESTADO_CUENTA')) {
          await stats.cargar(propiedadId: pid);
        }
        if (esPropietario || permisos.tienePermiso('ANUNCIOS')) {
          await anuncios.cargarResidente();
        }
        if (!esParqueadero && (esPropietario || permisos.tienePermiso('PQRS'))) {
          await pqrs.cargarMisPqrs();
        }
        if (!esParqueadero && (esPropietario || permisos.tienePermiso('VOTAR'))) {
          await votaciones.cargarResidente();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sección financiera (siempre visible, sin carousel) ──
            if (tengoPermiso) ...[
              Skeletonizer(
                enabled: stats.loading,
                child: stats.estadisticas != null
                    ? DeudaResumenWidget(
                        stats: stats.estadisticas!,
                        saldoFavor: stats.saldoFavor,
                        formatMonto: _fmt,
                        onVerEstadoCuenta: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EstadoCuentaScreen(),
                          ),
                        ),
                      )
                    : stats.error != null
                    ? _buildErrorDeuda(context, stats)
                    : Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Actividad reciente ──
            if (hayActividad) ...[
              Text(
                'Actividad reciente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActivityFeedWidget(
                ultimoPago: ultimoPago,
                formatMonto: _fmt,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Header con toggle grid/lista (visible para cualquier usuario)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Accesos rapidos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _esGridView ? 'Ver en lista' : 'Ver en cuadricula',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      _esGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      key: ValueKey(_esGridView),
                    ),
                  ),
                  onPressed: _toggleGridView,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            _buildAccesos(
              context: context,
              esPropietario: esPropietario,
              esParqueadero: esParqueadero,
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

  Widget _buildAccesos({
    required BuildContext context,
    required bool esPropietario,
    required bool esParqueadero,
    required InquilinoPermisosProvider permisos,
    required AnuncioProvider anuncios,
    required PqrProvider pqrs,
    required VotacionProvider votaciones,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool puede(String permiso) {
      if (esParqueadero) {
        const permitidosParqueadero = {'ESTADO_CUENTA', 'PQRS', 'ANUNCIOS'};
        if (!permitidosParqueadero.contains(permiso)) return false;
      }
      return esPropietario || permisos.tienePermiso(permiso);
    }

    final cards = <QuickAccessCard>[];
    final propiedadActual = context.read<PropiedadProvider>().propiedadActual;

    if (puede('ESTADO_CUENTA')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgBlue, AppColors.blue, isDark);
      cards.add(QuickAccessCard(
        label: 'Estado de Cuenta',
        subtitulo: 'Ver cobros y deudas',
        icono: Icons.account_balance_wallet_outlined,
        bg: palette.bg, //fondo del card
        fg: palette.fg, //letras del card
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('RESERVAS')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgOrange, AppColors.orange, isDark);
      cards.add(QuickAccessCard(
        label: 'Reservas',
        subtitulo: 'Areas comunes',
        icono: Icons.event_outlined,
        bg: palette.bg,
        fg: palette.fg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisReservasScreen()),
        ),
      ));
    }

    if (puede('PQRS')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgPurple, AppColors.purple, isDark);
      cards.add(QuickAccessCard(
        label: 'PQRs',
        subtitulo: pqrs.cantidadPendientes > 0
            ? '${pqrs.cantidadPendientes} pendiente${pqrs.cantidadPendientes == 1 ? '' : 's'}'
            : 'Sin pendientes',
        icono: Icons.support_agent_outlined,
        bg: palette.bg,
        fg: palette.fg,
        badge: pqrs.cantidadPendientes > 0 ? pqrs.cantidadPendientes : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
        ),
      ));
    }

    if (puede('ANUNCIOS')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgGreen, AppColors.green, isDark);
      cards.add(QuickAccessCard(
        label: 'Anuncios',
        subtitulo: anuncios.noVistos > 0
            ? '${anuncios.noVistos} nuevo${anuncios.noVistos == 1 ? '' : 's'}'
            : 'Sin novedades',
        icono: Icons.campaign_outlined,
        bg: palette.bg,
        fg: palette.fg,
        badge: anuncios.noVistos > 0 ? anuncios.noVistos : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisAnunciosScreen()),
        ),
      ));
    }

    // Documentos de interés general: visible para propietarios e inquilinos.
    if (esPropietario || permisos.tienePermiso('DOCUMENTOS')) {
      final palette =
          PaletteQuickAccessCard.resolve(AppColors.bgBlue, AppColors.blue, isDark);
      cards.add(QuickAccessCard(
        label: 'Documentos',
        subtitulo: 'Interés general',
        icono: Icons.folder_copy_outlined,
        bg: palette.bg,
        fg: palette.fg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DocumentosResidenteScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('VOTAR')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgYellow, AppColors.yellow, isDark);
      cards.add(QuickAccessCard(
        label: 'Votaciones',
        subtitulo: votaciones.pendientesDeVotar > 0
            ? '${votaciones.pendientesDeVotar} ${votaciones.pendientesDeVotar == 1 ? 'votacion abierta' : 'votaciones abiertas'}'
            : 'Sin votaciones activas',
        icono: Icons.how_to_vote_outlined,
        bg: palette.bg,
        fg: palette.fg,
        badge: votaciones.pendientesDeVotar > 0
            ? votaciones.pendientesDeVotar
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisVotacionesScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('MARKETPLACE')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgTeal, AppColors.teal, isDark);
      cards.add(QuickAccessCard(
        label: 'Marketplace',
        subtitulo: 'Compra y vende en el conjunto',
        icono: Icons.storefront_outlined,
        bg: palette.bg,
        fg: palette.fg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
        ),
      ));
    }

    // Visitas con QR — propietario siempre; inquilino con permiso VISITAS
    if (!esParqueadero && puede('VISITAS')) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgCoral, AppColors.coral, isDark);
      cards.add(QuickAccessCard(
        label: 'Visitas',
        subtitulo: 'Genera el QR de tus invitados',
        icono: Icons.qr_code_2_outlined,
        bg: palette.bg,
        fg: palette.fg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisVisitasScreen()),
        ),
      ));
    }

    // Paquetería recibida en portería
    final palette =  PaletteQuickAccessCard.resolve(AppColors.bgSlate, AppColors.slate, isDark);
    cards.add(QuickAccessCard(
      label: 'Paquetes',
      subtitulo: 'Correspondencia en portería',
      icono: Icons.inventory_2_outlined,
      bg: palette.bg,
      fg: palette.fg,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MisPaquetesScreen()),
      ),
    ));

    if (!esParqueadero && puede('ESTADO_CUENTA')) {
      final planProvider = context.read<PlanPagoProvider>();
      final tienePlan = planProvider.planes.any((p) => p.esActivo || p.esPendiente);
      final moduloActivo = planProvider.config.activo;
      if (tienePlan || moduloActivo) {
        final planActivo = planProvider.planes.where((p) => p.esActivo).firstOrNull;
        cards.add(QuickAccessCard(
          label: 'Plan de pago',
          subtitulo: planActivo != null
              ? '${planActivo.cuotasPagadas}/${planActivo.numeroCuotas} cuotas pagadas'
              : 'Fracciona tu deuda',
          icono: Icons.calendar_month_outlined,
          fg: AppColors.orange,
          bg: AppColors.bgOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResidenteMiPlanScreen()),
          ),
        ));
      }
    }

    if (!esParqueadero) {
      final presupuestoProvider = context.read<PresupuestoProvider>();
      if (presupuestoProvider.activo != null) {
        final p = presupuestoProvider.activo!;
        final palette =  PaletteQuickAccessCard.resolve(AppColors.bgLime, AppColors.lime, isDark);
        cards.add(QuickAccessCard(
          label: 'Presupuesto',
          subtitulo: '${p.porcentajeEjecucionGeneral.toStringAsFixed(0)}% ejecutado - ${p.anio}',
          icono: Icons.account_balance_outlined,
          bg: palette.bg,
          fg: palette.fg,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ResidentePresupuestoScreen()),
          ),
        ));
      }
    }

    if (propiedadActual != null) {
      final palette =  PaletteQuickAccessCard.resolve(AppColors.bgCyan, AppColors.cyan, isDark);
      final cardParqueadero = QuickAccessCard(
        label: esParqueadero ? 'Mi Parqueadero' : 'Parqueaderos',
        subtitulo: esParqueadero
            ? 'Gestionar vehiculos y accesos'
            : 'Mis vehiculos y parqueaderos',
        icono: Icons.local_parking,
        bg: palette.bg,
        fg: palette.fg,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MisParqueaderosResidenteScreen(
              propiedadId: propiedadActual.propiedadId,
            ),
          ),
        ),
      );
      if (esParqueadero) {
        cards.insert(0, cardParqueadero);
      } else {
        cards.add(cardParqueadero);
      }
    }

    if (cards.isEmpty) {
      return const _SinAccesosWidget();
    }

    // Vista grid (disponible para cualquier usuario que active el toggle)
    if (_esGridView) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.6,
        children: cards
            .map((c) => QuickAccessCard(
                  key: c.key,
                  label: c.label,
                  icono: c.icono,
                  fg: c.fg,
                  bg: c.bg,
                  badge: c.badge,
                  onTap: c.onTap,
                  isGrid: true,
                ))
            .toList(),
      );
    }

    // Vista lista (default)
    return Column(
      children: cards
          .expand((c) => [c, const SizedBox(height: AppSpacing.sm)])
          .toList()
        ..removeLast(),
    );
  }
}

class _SinAccesosWidget extends StatelessWidget {
  const _SinAccesosWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
