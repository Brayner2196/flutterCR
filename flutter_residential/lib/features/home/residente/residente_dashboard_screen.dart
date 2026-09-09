import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/widgets/quick_access_cards.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inquilinos/providers/inquilino_permisos_provider.dart';
import '../../modulos/providers/modulos_provider.dart';
import '../../../core/enums/modulo.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final permisos = context.read<InquilinoPermisosProvider>();
      final modulos = context.read<ModulosProvider>();
      final propProvider = context.read<PropiedadProvider>();

      // Doble condición en cada carga: el módulo debe estar contratado por el
      // conjunto Y el usuario debe tener el permiso. Si el módulo está
      // apagado ni siquiera se dispara la petición: el backend respondería
      // 403 y solo ensuciaría los logs.
      if (modulos.activo(Modulo.anuncios) &&
          (auth.isPropietario || permisos.tienePermiso('ANUNCIOS'))) {
        context.read<AnuncioProvider>().cargarResidente();
      }
      if (modulos.activo(Modulo.pqr) &&
          (auth.isPropietario || permisos.tienePermiso('PQRS'))) {
        context.read<PqrProvider>().cargarMisPqrs();
      }
      if (modulos.activo(Modulo.votaciones) &&
          (auth.isPropietario || permisos.tienePermiso('VOTAR'))) {
        context.read<VotacionProvider>().cargarResidente();
      }
      if (modulos.activo(Modulo.planesPago) &&
          (auth.isPropietario || permisos.tienePermiso('ESTADO_CUENTA'))) {
        context.read<PlanPagoProvider>().cargarConfigResidente();
        context.read<PlanPagoProvider>().cargarMisPlanes();
      }
      if (modulos.activo(Modulo.presupuesto)) {
        context.read<PresupuestoProvider>().cargarActivo();
      }

      final pid = propProvider.propiedadActual?.propiedadId;
      if (pid != null) {
        _cargarEstadisticas(pid);
      } else {
        propProvider.addListener(_onPropiedadLista);
      }
    });
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
    final modulos = context.watch<ModulosProvider>();
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
        if (modulos.activo(Modulo.anuncios) &&
            (esPropietario || permisos.tienePermiso('ANUNCIOS'))) {
          await anuncios.cargarResidente();
        }
        if (!esParqueadero &&
            modulos.activo(Modulo.pqr) &&
            (esPropietario || permisos.tienePermiso('PQRS'))) {
          await pqrs.cargarMisPqrs();
        }
        if (!esParqueadero &&
            modulos.activo(Modulo.votaciones) &&
            (esPropietario || permisos.tienePermiso('VOTAR'))) {
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
              esParqueadero: esParqueadero,
              permisos: permisos,
              modulos: modulos,
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
    required ModulosProvider modulos,
    required AnuncioProvider anuncios,
    required PqrProvider pqrs,
    required VotacionProvider votaciones,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool puede(String permiso, [Modulo? modulo]) {
      if (modulo != null && !modulos.activo(modulo)) return false;
      if (esParqueadero) {
        const permitidosParqueadero = {'ESTADO_CUENTA', 'PQRS', 'ANUNCIOS'};
        if (!permitidosParqueadero.contains(permiso)) return false;
      }
      return esPropietario || permisos.tienePermiso(permiso);
    }

    final cards = <QuickAccessCardData>[];
    final propiedadActual = context.read<PropiedadProvider>().propiedadActual;

    if (puede('ESTADO_CUENTA')) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Estado cuenta',
        icon: Icons.account_balance_wallet_outlined,
        bgLight: AppColors.bgGreen,
        fgLight: AppColors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstadoCuentaScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('RESERVAS', Modulo.reservas)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Reservas',
        icon: Icons.event_outlined,
        bgLight: AppColors.bgOrange,
        fgLight: AppColors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisReservasScreen()),
        ),
      ));
    }

    if (puede('PQRS', Modulo.pqr)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'PQRs',
        icon: Icons.support_agent_outlined,
        bgLight: AppColors.bgYellow,
        fgLight: AppColors.yellow,
        badge: pqrs.cantidadPendientes,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisPqrsScreen()),
        ),
      ));
    }

    if (puede('ANUNCIOS', Modulo.anuncios)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Anuncios',
        icon: Icons.campaign_outlined,
        bgLight: AppColors.bgBlue,
        fgLight: AppColors.blue,
        badge: anuncios.noVistos,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisAnunciosScreen()),
        ),
      ));
    }

    // Documentos de interés general: visible para propietarios e inquilinos.
    if (modulos.activo(Modulo.documentos) &&
        (esPropietario || permisos.tienePermiso('DOCUMENTOS'))) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Documentos',
        icon: Icons.folder_copy_outlined,
        bgLight: AppColors.bgTeal,
        fgLight: AppColors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DocumentosResidenteScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('VOTAR', Modulo.votaciones)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Votaciones',
        icon: Icons.how_to_vote_outlined,
        bgLight: AppColors.bgPurple,
        fgLight: AppColors.purple,
        badge: votaciones.pendientesDeVotar,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisVotacionesScreen()),
        ),
      ));
    }

    if (!esParqueadero && puede('MARKETPLACE', Modulo.marketplace)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Marketplace',
        icon: Icons.storefront_outlined,
        bgLight: AppColors.bgTeal,
        fgLight: AppColors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
        ),
      ));
    }

    // Visitas con QR — propietario siempre; inquilino con permiso VISITAS
    if (!esParqueadero && puede('VISITAS', Modulo.visitas)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Visitas',
        icon: Icons.qr_code_2_outlined,
        bgLight: AppColors.bgOrange,
        fgLight: AppColors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisVisitasScreen()),
        ),
      ));
    }

    // Paquetería recibida en portería
    if (modulos.activo(Modulo.paquetes)) {
      cards.add(QuickAccessCardData.tema(
        isDark: isDark,
        title: 'Paquetes',
        icon: Icons.inventory_2_outlined,
        bgLight: AppColors.bgBlue,
        fgLight: AppColors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisPaquetesScreen()),
        ),
      ));
    }

    if (!esParqueadero &&
        modulos.activo(Modulo.planesPago) &&
        puede('ESTADO_CUENTA')) {
      final planProvider = context.read<PlanPagoProvider>();
      final tienePlan =
          planProvider.planes.any((p) => p.esActivo || p.esPendiente);
      final moduloActivo = planProvider.config.activo;
      if (tienePlan || moduloActivo) {
        cards.add(QuickAccessCardData.tema(
          isDark: isDark,
          title: 'Plan de pago',
          icon: Icons.calendar_month_outlined,
          bgLight: AppColors.bgPurple,
          fgLight: AppColors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResidenteMiPlanScreen()),
          ),
        ));
      }
    }

    if (!esParqueadero && modulos.activo(Modulo.presupuesto)) {
      final presupuestoProvider = context.read<PresupuestoProvider>();
      if (presupuestoProvider.activo != null) {
        cards.add(QuickAccessCardData.tema(
          isDark: isDark,
          title: 'Presupuesto',
          icon: Icons.account_balance_outlined,
          bgLight: AppColors.bgLime,
          fgLight: AppColors.lime,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ResidentePresupuestoScreen()),
          ),
        ));
      }
    }

    if (propiedadActual != null && modulos.activo(Modulo.parqueaderos)) {
      final cardParqueadero = QuickAccessCardData.tema(
        isDark: isDark,
        title: esParqueadero ? 'Mi Parqueadero' : 'Parqueaderos',
        icon: Icons.local_parking,
        bgLight: AppColors.bgCyan,
        fgLight: AppColors.cyan,
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

    if (cards.isEmpty) return const _SinAccesosWidget();

    // El SingleChildScrollView ya aplica AppSpacing.md; el padding propio del
    // grid duplicaría el margen y desalinearía con la tarjeta de deuda.
    return QuickAccessGrid(cards: cards, padding: EdgeInsets.zero);
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
