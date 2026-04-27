import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../models/dashboard/cartera_vencida.dart';
import '../../../../../models/dashboard/dashboard_resumen.dart';
import '../../../../../models/dashboard/estado_unidades.dart';
import '../../../../../models/dashboard/pagos_por_verificar.dart';
import '../../../../../models/dashboard/pendientes_hoy.dart';
import '../../../../../models/dashboard/recaudo_mes.dart';
import '../../../../../models/dashboard/tendencia.dart';
import '../../../../../providers/dashboard_provider.dart';
import 'cartera_vencida_card.dart';
import 'dashboard_tokens.dart';
import 'estado_unidades_card.dart';
import 'pagos_por_verificar_card.dart';
import 'pendientes_hoy_card.dart';
import 'recaudo_mes_card.dart';
import 'tendencia_recaudo_chart.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback? onTapComprobantes;
  final VoidCallback? onTapPqrs;
  final VoidCallback? onTapReservas;
  final VoidCallback? onTapPagos;

  const AdminDashboard({
    super.key,
    this.onTapComprobantes,
    this.onTapPqrs,
    this.onTapReservas,
    this.onTapPagos,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();

    if (p.error != null && p.resumen == null) {
      return _ErrorState(
        mensaje: p.error!,
        onRetry: () => context.read<DashboardProvider>().cargar(),
      );
    }

    final cargando = p.loading && p.resumen == null;
    final resumen = p.resumen ?? _placeholder;

    return Skeletonizer(
      enabled: cargando,
      child: _Contenido(
        resumen: resumen,
        encabezado: _encabezado(resumen),
        nombreMes: _meses[resumen.recaudoMes.mes - 1],
        onTapComprobantes: widget.onTapComprobantes,
        onTapPqrs: widget.onTapPqrs,
        onTapReservas: widget.onTapReservas,
        onTapPagos: widget.onTapPagos,
      ),
    );
  }

  String _encabezado(DashboardResumen r) {
    final pendientes = r.pendientesHoy.total;
    final puntos = r.recaudoMes.puntosVariacion;
    final dirRecaudo = puntos == 0
        ? 'igual al mes pasado'
        : (puntos > 0
            ? '$puntos puntos por encima del mes pasado'
            : '${-puntos} puntos por debajo del mes pasado');
    return 'Tienes $pendientes ${pendientes == 1 ? 'cosa pendiente' : 'cosas pendientes'} y el recaudo va $dirRecaudo.';
  }
}

class _Contenido extends StatelessWidget {
  final DashboardResumen resumen;
  final String encabezado;
  final String nombreMes;
  final VoidCallback? onTapComprobantes;
  final VoidCallback? onTapPqrs;
  final VoidCallback? onTapReservas;
  final VoidCallback? onTapPagos;

  const _Contenido({
    required this.resumen,
    required this.encabezado,
    required this.nombreMes,
    this.onTapComprobantes,
    this.onTapPqrs,
    this.onTapReservas,
    this.onTapPagos,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          encabezado,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 14),
        PendientesHoyCard(
          data: resumen.pendientesHoy,
          onTapComprobantes: onTapComprobantes,
          onTapPqrs: onTapPqrs,
          onTapReservas: onTapReservas,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RESUMEN DEL MES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              nombreMes,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DashboardTokens.fgPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: RecaudoMesCard(data: resumen.recaudoMes),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: CarteraVencidaCard(data: resumen.carteraVencida)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PagosPorVerificarCard(
                        data: resumen.pagosPorVerificar,
                        onTap: onTapPagos,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TendenciaRecaudoChart(data: resumen.tendencia),
        const SizedBox(height: 14),
        EstadoUnidadesCard(data: resumen.estadoUnidades),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorState({required this.mensaje, required this.onRetry});

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

// Datos de placeholder usados durante el skeleton.
final _placeholder = DashboardResumen(
  pendientesHoy: const PendientesHoy(comprobantes: 7, pqrs: 2, reservas: 1, total: 10),
  recaudoMes: const RecaudoMes(
      anio: 2025, mes: 4, porcentaje: 74, puntosVariacion: 6,
      recaudado: 38400000, esperado: 51800000),
  carteraVencida: const CarteraVencida(monto: 13400000, variacionMonto: -1200000, unidadesEnMora: 18),
  pagosPorVerificar: const PagosPorVerificar(cantidad: 7),
  tendencia: const Tendencia(meses: [
    TendenciaMes(anio: 2024, mes: 11, etiqueta: 'NOV', porcentaje: 60),
    TendenciaMes(anio: 2024, mes: 12, etiqueta: 'DIC', porcentaje: 55),
    TendenciaMes(anio: 2025, mes: 1, etiqueta: 'ENE', porcentaje: 50),
    TendenciaMes(anio: 2025, mes: 2, etiqueta: 'FEB', porcentaje: 65),
    TendenciaMes(anio: 2025, mes: 3, etiqueta: 'MAR', porcentaje: 70),
    TendenciaMes(anio: 2025, mes: 4, etiqueta: 'ABR', porcentaje: 74),
  ], tendencia: 'MEJORANDO'),
  estadoUnidades: const EstadoUnidades(total: 120, alDia: 94, porVencer: 8, enMora: 18),
);
