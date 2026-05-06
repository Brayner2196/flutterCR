import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../models/dashboard/cartera_vencida.dart';
import '../../../../../models/dashboard/dashboard_resumen.dart';
import '../../../../../models/dashboard/estado_unidades.dart';
import '../../../../../models/dashboard/pendientes_hoy.dart';
import '../../../../../models/dashboard/pagos_por_verificar.dart';
import '../../../../../models/dashboard/recaudo_mes.dart';
import '../../../../../models/dashboard/tendencia.dart';
import '../../../../../providers/dashboard_provider.dart';
import '../dashboard/dashboard_tokens.dart';
import '../dashboard/tendencia_recaudo_chart.dart';
import 'kpi_incidencias_pqr.dart';
import 'kpi_morosidad.dart';
import 'kpi_recaudo_mensual.dart';

/// Carousel infinito con los 4 KPI principales del admin.
/// Se auto-desplaza cada 3 segundos; pausa al interactuar.
class KpiCarouselDashboard extends StatefulWidget {
  final VoidCallback? onTapPqrs;
  final VoidCallback? onTapPagos;
  final VoidCallback? onTapReservas;
  final VoidCallback? onTapComprobantes;

  const KpiCarouselDashboard({
    super.key,
    this.onTapPqrs,
    this.onTapPagos,
    this.onTapReservas,
    this.onTapComprobantes,
  });

  @override
  State<KpiCarouselDashboard> createState() => _KpiCarouselDashboardState();
}

class _KpiCarouselDashboardState extends State<KpiCarouselDashboard> {
  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _totalPaginas = 4;
  // Inicio en el medio de un número grande para simular scroll infinito
  static const _offsetInicial = 10000;

  late final PageController _pageController;
  Timer? _timer;
  int _paginaReal = 0; // 0..3

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: _offsetInicial, viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().cargar();
      _iniciarAutoScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _iniciarAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pausarYReanudar() {
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _iniciarAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();

    if (p.error != null && p.resumen == null) {
      return _ErrorCarousel(
        mensaje: p.error!,
        onRetry: () => context.read<DashboardProvider>().cargar(),
      );
    }

    final cargando = p.loading && p.resumen == null;
    final resumen = p.resumen ?? _placeholder;

    return Skeletonizer(
      enabled: cargando,
      child: Column(
        children: [
          // ── PageView ──────────────────────────────────
          SizedBox(
            height: 315,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification) _pausarYReanudar();
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _paginaReal = idx % _totalPaginas);
                },
                itemBuilder: (context, idx) {
                  final pagina = idx % _totalPaginas;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildPagina(pagina, resumen),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Dots indicator ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPaginas, (i) {
              final activo = i == _paginaReal;
              return GestureDetector(
                onTap: () {
                  _pausarYReanudar();
                  final paginaActual =
                      _pageController.page?.round() ?? _offsetInicial;
                  final diff = i - _paginaReal;
                  _pageController.animateToPage(
                    paginaActual + diff,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: activo ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activo
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPagina(int pagina, DashboardResumen resumen) {
    switch (pagina) {
      case 0:
        return KpiRecaudoMensual(
          data: resumen.recaudoMes,
          nombreMes: _meses[resumen.recaudoMes.mes - 1],
        );
      case 1:
        return TendenciaRecaudoChart(data: resumen.tendencia);
      case 2:
        return KpiMorosidad(
          cartera: resumen.carteraVencida,
          unidades: resumen.estadoUnidades,
        );
      case 3:
        return KpiIncidenciasPqr(
          data: resumen.pendientesHoy,
          onTapPqrs: widget.onTapPqrs,
          onTapPagos: widget.onTapComprobantes,
          onTapReservas: widget.onTapReservas,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Widget de error ─────────────────────────────────────────────────────────

class _ErrorCarousel extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorCarousel({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 18),
              const SizedBox(width: 6),
              const Text('No se pudo cargar el dashboard',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(mensaje,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─── Datos placeholder para skeleton ─────────────────────────────────────────

final _placeholder = DashboardResumen(
  pendientesHoy:
      const PendientesHoy(comprobantes: 7, pqrs: 5, reservas: 3, total: 15),
  recaudoMes: const RecaudoMes(
    anio: 2025,
    mes: 5,
    porcentaje: 78,
    puntosVariacion: 6,
    recaudado: 40400000,
    esperado: 51800000,
    recaudadoCobrosViejos: 8290000,
  ),
  carteraVencida: const CarteraVencida(
    monto: 10700000,
    variacionMonto: -1200000,
    unidadesEnMora: 18,
  ),
  pagosPorVerificar: const PagosPorVerificar(cantidad: 7),
  tendencia: const Tendencia(
    meses: [
      TendenciaMes(anio: 2024, mes: 12, etiqueta: 'DIC', porcentaje: 55),
      TendenciaMes(anio: 2025, mes: 1, etiqueta: 'ENE', porcentaje: 50),
      TendenciaMes(anio: 2025, mes: 2, etiqueta: 'FEB', porcentaje: 65),
      TendenciaMes(anio: 2025, mes: 3, etiqueta: 'MAR', porcentaje: 70),
      TendenciaMes(anio: 2025, mes: 4, etiqueta: 'ABR', porcentaje: 72),
      TendenciaMes(anio: 2025, mes: 5, etiqueta: 'MAY', porcentaje: 78),
    ],
    tendencia: 'MEJORANDO',
  ),
  estadoUnidades:
      const EstadoUnidades(total: 120, alDia: 94, porVencer: 8, enMora: 18),
);
