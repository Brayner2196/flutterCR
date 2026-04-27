import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../models/dashboard/tendencia.dart';
import 'dashboard_tokens.dart';

class TendenciaRecaudoChart extends StatelessWidget {
  final Tendencia data;

  const TendenciaRecaudoChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tendencia de recaudo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Últimos 6 meses',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              _BadgeTendencia(tendencia: data.tendencia),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(_buildChartData(cs)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(ColorScheme cs) {
    final spots = <FlSpot>[
      for (int i = 0; i < data.meses.length; i++)
        FlSpot(i.toDouble(), data.meses[i].porcentaje.toDouble()),
    ];
    final color = data.esEmpeorando
        ? DashboardTokens.fgRed
        : DashboardTokens.fgGreen;

    return LineChartData(
      minX: 0,
      maxX: (data.meses.length - 1).toDouble().clamp(0, double.infinity),
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= data.meses.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  data.meses[i].etiqueta,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    '${s.y.toInt()}%',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          barWidth: 2.5,
          color: color,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: index == spots.length - 1 ? 4 : 0,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _BadgeTendencia extends StatelessWidget {
  final String tendencia;
  const _BadgeTendencia({required this.tendencia});

  @override
  Widget build(BuildContext context) {
    final esEmpeorando = tendencia == 'EMPEORANDO';
    final esMejorando = tendencia == 'MEJORANDO';
    Color bg;
    Color fg;
    IconData icon;
    String label;
    if (esMejorando) {
      bg = DashboardTokens.bgGreen;
      fg = DashboardTokens.fgGreen;
      icon = Icons.trending_up;
      label = 'Mejorando';
    } else if (esEmpeorando) {
      bg = DashboardTokens.bgRed;
      fg = DashboardTokens.fgRed;
      icon = Icons.trending_down;
      label = 'Empeorando';
    } else {
      bg = DashboardTokens.bgYellow;
      fg = DashboardTokens.fgYellow;
      icon = Icons.trending_flat;
      label = 'Estable';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
