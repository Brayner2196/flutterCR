import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/consejo_estadisticas_model.dart';
import '../services/consejo_service.dart';

/// Dashboard de estadísticas del Consejo Comunal.
/// Filtros de período: 1 mes, 3 meses, 6 meses, 1 año.
class ConsejoEstadisticasScreen extends StatefulWidget {
  const ConsejoEstadisticasScreen({super.key});

  @override
  State<ConsejoEstadisticasScreen> createState() =>
      _ConsejoEstadisticasScreenState();
}

class _ConsejoEstadisticasScreenState
    extends State<ConsejoEstadisticasScreen> {
  ConsejoEstadisticasModel? _datos;
  bool _loading = true;
  String? _error;

  // 1 = 1 mes, 3 = 3 meses, 6 = 6 meses, 12 = 1 año
  int _meses = 1;

  static const _periodos = [
    (1, 'Este mes'),
    (3, '3 meses'),
    (6, '6 meses'),
    (12, '1 año'),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final hasta = DateTime.now();
      final desde = DateTime(hasta.year, hasta.month - _meses + 1, 1);
      final d = _fmtFecha(desde);
      final h = _fmtFecha(hasta);
      final datos = await ConsejoService.listarEstadisticas(desde: d, hasta: h);
      if (mounted) setState(() { _datos = datos; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: Column(
        children: [
          // ── Filtros de período ──────────────────────────────────────────
          _PeriodBar(
            seleccionado: _meses,
            periodos: _periodos,
            onChanged: (m) {
              setState(() => _meses = m);
              _cargar();
            },
          ),
          // ── Contenido ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.error)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            _SeccionPqrs(datos: _datos!),
                            const SizedBox(height: 20),
                            _SeccionAnuncios(datos: _datos!),
                            const SizedBox(height: 20),
                            _SeccionVotaciones(datos: _datos!),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de filtros de período ──────────────────────────────────────────────

class _PeriodBar extends StatelessWidget {
  final int seleccionado;
  final List<(int, String)> periodos;
  final void Function(int) onChanged;

  const _PeriodBar({
    required this.seleccionado,
    required this.periodos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periodos.map((p) {
            final activo = seleccionado == p.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onChanged(p.$1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: activo ? cs.primary : cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activo ? cs.primary : cs.outline),
                  ),
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      color: activo ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Sección PQRs ─────────────────────────────────────────────────────────────

class _SeccionPqrs extends StatelessWidget {
  final ConsejoEstadisticasModel datos;
  const _SeccionPqrs({required this.datos});

  static const _estadoOrden = [
    'RADICADA',
    'EN_PROCESO',
    'RESUELTO',
    'CERRADO',
    'RECHAZADA',
  ];
  static const _estadoLabel = {
    'RADICADA': 'Radicadas',
    'EN_PROCESO': 'En proceso',
    'RESUELTO': 'Resueltas',
    'CERRADO': 'Cerradas',
    'RECHAZADA': 'Rechazadas',
  };
  static const _estadoColor = {
    'RADICADA':   Color(0xFFB45309),
    'EN_PROCESO': Color(0xFF7B6000),
    'RESUELTO':   Color(0xFF166534),
    'CERRADO':    Color(0xFF616161),
    'RECHAZADA':  Color(0xFFC62828),
  };
  static const _estadoBg = {
    'RADICADA':   Color(0xFFFFE8CC),
    'EN_PROCESO': Color(0xFFFFF9C4),
    'RESUELTO':   Color(0xFFDCFCE7),
    'CERRADO':    Color(0xFFE0E0E0),
    'RECHAZADA':  Color(0xFFFFEBEE),
  };

  @override
  Widget build(BuildContext context) {
    final tiempoTexto = datos.pqrTiempoPromRespuestaHoras == null
        ? 'N/A'
        : datos.pqrTiempoPromRespuestaHoras! < 24
            ? '${datos.pqrTiempoPromRespuestaHoras!.toStringAsFixed(0)} h'
            : '${(datos.pqrTiempoPromRespuestaHoras! / 24).toStringAsFixed(1)} días';

    return _Seccion(
      titulo: 'PQRs',
      icono: Icons.support_agent_rounded,
      color: AppColors.orange,
      children: [
        // KPIs
        Row(
          children: [
            _KpiBox(valor: '${datos.pqrTotal}', label: 'Total', color: AppColors.orange),
            const SizedBox(width: 10),
            _KpiBox(valor: '${datos.pqrPendientes}', label: 'Pendientes', color: const Color(0xFFB45309)),
            const SizedBox(width: 10),
            _KpiBox(valor: '${datos.pqrResueltas}', label: 'Resueltas', color: AppColors.green),
          ],
        ),
        const SizedBox(height: 14),
        // Tasa + tiempo
        Row(
          children: [
            _KpiBox(
              valor: '${(datos.tasaResolucionPqr * 100).toStringAsFixed(0)}%',
              label: 'Tasa resolución',
              color: AppColors.blue,
            ),
            const SizedBox(width: 10),
            _KpiBox(
              valor: tiempoTexto,
              label: 'Tiempo prom. resp.',
              color: AppColors.purple,
            ),
          ],
        ),
        if (datos.pqrPorEstado.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SubTitulo('Por estado'),
          const SizedBox(height: 8),
          ..._estadoOrden.where((e) => datos.pqrPorEstado.containsKey(e)).map((e) {
            final count = datos.pqrPorEstado[e] ?? 0;
            final pct = datos.pqrTotal == 0 ? 0.0 : count / datos.pqrTotal;
            return _BarraEstado(
              label: _estadoLabel[e] ?? e,
              count: count,
              pct: pct,
              color: _estadoColor[e] ?? AppColors.orange,
              bg: _estadoBg[e] ?? const Color(0xFFFFE8CC),
            );
          }),
        ],
        if (datos.pqrPorTipo.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SubTitulo('Por tipo'),
          const SizedBox(height: 8),
          Row(
            children: datos.pqrPorTipo.entries.map((e) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TipoChip(tipo: e.key, count: e.value),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Sección Anuncios ─────────────────────────────────────────────────────────

class _SeccionAnuncios extends StatelessWidget {
  final ConsejoEstadisticasModel datos;
  const _SeccionAnuncios({required this.datos});

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Anuncios',
      icono: Icons.campaign_rounded,
      color: AppColors.blue,
      children: [
        Row(
          children: [
            _KpiBox(valor: '${datos.anuncioTotal}', label: 'Publicados', color: AppColors.blue),
            const SizedBox(width: 10),
            _KpiBox(valor: '${datos.anuncioActivos}', label: 'Activos', color: AppColors.green),
            const SizedBox(width: 10),
            _KpiBox(valor: '${datos.anuncioTotalVistas}', label: 'Lecturas', color: AppColors.purple),
          ],
        ),
        if (datos.anuncioTotal > 0) ...[
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Anuncios activos',
            value: datos.anuncioActivos,
            total: datos.anuncioTotal,
            color: AppColors.blue,
          ),
        ],
      ],
    );
  }
}

// ─── Sección Votaciones ───────────────────────────────────────────────────────

class _SeccionVotaciones extends StatelessWidget {
  final ConsejoEstadisticasModel datos;
  const _SeccionVotaciones({required this.datos});

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Votaciones',
      icono: Icons.how_to_vote_rounded,
      color: AppColors.green,
      children: [
        Row(
          children: [
            _KpiBox(valor: '${datos.votacionTotal}', label: 'Total', color: AppColors.green),
            const SizedBox(width: 10),
            _KpiBox(
              valor: '${datos.votacionesAbiertas}',
              label: 'Abiertas',
              color: AppColors.orange,
            ),
            const SizedBox(width: 10),
            _KpiBox(
              valor: '${datos.votacionParticipantes}',
              label: 'Participantes',
              color: AppColors.blue,
            ),
          ],
        ),
        if (datos.votacionPorEstado.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SubTitulo('Por estado'),
          const SizedBox(height: 8),
          ...{
            'ABIERTA':  ('Abiertas',  AppColors.green,  const Color(0xFFDCFCE7)),
            'CERRADA':  ('Cerradas',  const Color(0xFF616161), const Color(0xFFE0E0E0)),
            'BORRADOR': ('Borradores', AppColors.blue,  const Color(0xFFDBEAFE)),
          }.entries
              .where((e) => datos.votacionPorEstado.containsKey(e.key))
              .map((e) {
            final count = datos.votacionPorEstado[e.key] ?? 0;
            final pct = datos.votacionTotal == 0 ? 0.0 : count / datos.votacionTotal;
            return _BarraEstado(
              label: e.value.$1,
              count: count,
              pct: pct,
              color: e.value.$2,
              bg: e.value.$3,
            );
          }),
        ],
      ],
    );
  }
}

// ─── Widgets comunes ──────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<Widget> children;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;

  const _KpiBox({required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraEstado extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  final Color bg;

  const _BarraEstado({
    required this.label,
    required this.count,
    required this.pct,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count (${(pct * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text('$value / $total',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _TipoChip extends StatelessWidget {
  final String tipo;
  final int count;

  const _TipoChip({required this.tipo, required this.count});

  static const _label = {
    'PETICION': 'Petición',
    'QUEJA':    'Queja',
    'RECLAMO':  'Reclamo',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            _label[tipo] ?? tipo,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SubTitulo extends StatelessWidget {
  final String text;
  const _SubTitulo(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─── Helper de formato de fecha ───────────────────────────────────────────────

String _fmtFecha(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
