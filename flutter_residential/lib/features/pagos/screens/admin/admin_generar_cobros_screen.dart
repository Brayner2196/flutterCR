import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../models/periodo_cobro_model.dart';
import '../../providers/cobros_provider.dart';
import '../../../../shared/theme/app_theme.dart';

// ─── Modelo de preview ────────────────────────────────────────────────────────

class _PreviewData {
  final int anio;
  final int mes;
  final int totalPropiedades;
  final int yaGenerados;
  final int pendientesDeGenerar;
  final double montoTotalEstimado;
  final List<_GrupoDetalle> grupos;
  final List<String> advertencias;

  const _PreviewData({
    required this.anio,
    required this.mes,
    required this.totalPropiedades,
    required this.yaGenerados,
    required this.pendientesDeGenerar,
    required this.montoTotalEstimado,
    required this.grupos,
    required this.advertencias,
  });

  factory _PreviewData.fromJson(Map<String, dynamic> j) => _PreviewData(
        anio: j['anio'] as int,
        mes: j['mes'] as int,
        totalPropiedades: j['totalPropiedades'] as int,
        yaGenerados: j['yaGenerados'] as int,
        pendientesDeGenerar: j['pendientesDeGenerar'] as int,
        montoTotalEstimado: (j['montoTotalEstimado'] as num).toDouble(),
        grupos: (j['grupos'] as List)
            .map((g) => _GrupoDetalle.fromJson(g))
            .toList(),
        advertencias:
            (j['advertencias'] as List).map((e) => e.toString()).toList(),
      );
}

class _GrupoDetalle {
  final String nombreTipo;
  final String periodicidad;
  final int cantidad;
  final double montoPorUnidad;
  final double subtotal;

  const _GrupoDetalle({
    required this.nombreTipo,
    required this.periodicidad,
    required this.cantidad,
    required this.montoPorUnidad,
    required this.subtotal,
  });

  factory _GrupoDetalle.fromJson(Map<String, dynamic> j) => _GrupoDetalle(
        nombreTipo: j['nombreTipo'] as String,
        periodicidad: j['periodicidad'] as String,
        cantidad: j['cantidad'] as int,
        montoPorUnidad: (j['montoPorUnidad'] as num).toDouble(),
        subtotal: (j['subtotal'] as num).toDouble(),
      );
}

// ─── Screen principal ─────────────────────────────────────────────────────────

class AdminGenerarCobrosScreen extends StatefulWidget {
  final PeriodoCobroModel? periodo;
  const AdminGenerarCobrosScreen({super.key, this.periodo});

  @override
  State<AdminGenerarCobrosScreen> createState() =>
      _AdminGenerarCobrosScreenState();
}

class _AdminGenerarCobrosScreenState extends State<AdminGenerarCobrosScreen> {
  // Paso actual: 0=Período, 1=Preview, 2=Generando
  int _paso = 0;

  // Datos del período
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 10));
  bool _cargandoSugerencia = false;

  // Preview
  _PreviewData? _preview;
  bool _cargandoPreview = false;

  // Generación
  bool _creandoPeriodo = false;
  bool _generando = false;

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.periodo != null) {
      _anio = widget.periodo!.anio;
      _mes = widget.periodo!.mes;
    } else {
      _cargarSugerencia();
    }
  }

  Future<void> _cargarSugerencia() async {
    setState(() => _cargandoSugerencia = true);
    try {
      final res = await ApiClient.get(ApiConstants.proximoPeriodo,
          requiresAuth: true);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _anio = body['anio'] as int;
          _mes = body['mes'] as int;
        });
      }
    } catch (_) {
      // Si falla, mantenemos el mes actual
    } finally {
      if (mounted) setState(() => _cargandoSugerencia = false);
    }
  }

  Future<void> _cargarPreview() async {
    setState(() {
      _cargandoPreview = true;
      _paso = 1;
    });
    try {
      final res = await ApiClient.get(
        ApiConstants.previewGenerarCobros(_anio, _mes),
        requiresAuth: true,
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _preview = _PreviewData.fromJson(jsonDecode(res.body));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _paso = 0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo cargar la vista previa'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _cargandoPreview = false);
    }
  }

  Future<void> _ejecutar() async {
    setState(() {
      _paso = 2;
      _generando = true;
    });
    final provider = context.read<CobrosProvider>();
    try {
      PeriodoCobroModel? periodo = widget.periodo;
      if (periodo == null) {
        setState(() => _creandoPeriodo = true);
        final inicio = DateTime(_anio, _mes, 1);
        final fin = DateTime(_anio, _mes + 1, 0);
        periodo = await provider.abrirPeriodo({
          'anio': _anio,
          'mes': _mes,
          'fechaInicio': _fmtDate(inicio),
          'fechaFin': _fmtDate(fin),
          'fechaLimitePago': _fmtDate(_fechaLimite),
        });
        if (mounted) setState(() => _creandoPeriodo = false);
      }
      final cobros = await provider.generarCobros(periodo.anio, periodo.mes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${cobros.length} cobros generados correctamente'),
          backgroundColor: AppColors.ok,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paso = 1); // Regresa al preview
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _creandoPeriodo = false;
          _generando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar cobros'),
        leading: _paso > 0 && !_generando
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _paso = _paso - 1;
                  if (_paso == 0) _preview = null;
                }),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildPaso(),
      ),
    );
  }

  Widget _buildPaso() {
    return switch (_paso) {
      0 => _PasoPeriodo(
          key: const ValueKey('paso0'),
          anio: _anio,
          mes: _mes,
          fechaLimite: _fechaLimite,
          meses: _meses,
          cargandoSugerencia: _cargandoSugerencia,
          periodoFijo: widget.periodo,
          onAnioChanged: (v) => setState(() => _anio = v),
          onMesChanged: (v) => setState(() => _mes = v),
          onFechaLimiteChanged: (v) => setState(() => _fechaLimite = v),
          onSiguiente: _cargarPreview,
        ),
      1 => _PasoPreview(
          key: const ValueKey('paso1'),
          preview: _preview,
          cargando: _cargandoPreview,
          anio: _anio,
          mes: _mes,
          meses: _meses,
          onConfirmar: _ejecutar,
        ),
      2 => _PasoGenerando(
          key: const ValueKey('paso2'),
          creandoPeriodo: _creandoPeriodo,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Paso 1: Selección de período ─────────────────────────────────────────────

class _PasoPeriodo extends StatelessWidget {
  final int anio;
  final int mes;
  final DateTime fechaLimite;
  final List<String> meses;
  final bool cargandoSugerencia;
  final PeriodoCobroModel? periodoFijo;
  final ValueChanged<int> onAnioChanged;
  final ValueChanged<int> onMesChanged;
  final ValueChanged<DateTime> onFechaLimiteChanged;
  final VoidCallback onSiguiente;

  const _PasoPeriodo({
    super.key,
    required this.anio,
    required this.mes,
    required this.fechaLimite,
    required this.meses,
    required this.cargandoSugerencia,
    required this.periodoFijo,
    required this.onAnioChanged,
    required this.onMesChanged,
    required this.onFechaLimiteChanged,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Indicador de pasos
        _StepIndicator(paso: 0),
        const SizedBox(height: 24),

        Text('¿Para qué período?',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Se crearán los cobros de administración para todas las propiedades activas.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        if (periodoFijo != null)
          Card(
            color: AppColors.bgGreen,
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: AppColors.ok),
              title: Text(periodoFijo!.nombreMes,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Límite: ${periodoFijo!.fechaLimitePago}'),
            ),
          )
        else ...[
          // Auto-sugerencia
          if (cargandoSugerencia)
            const LinearProgressIndicator()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Período sugerido: ${meses[mes - 1]} $anio',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Selector año/mes
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: anio,
                  decoration: const InputDecoration(
                      labelText: 'Año', border: OutlineInputBorder()),
                  items: List.generate(
                          3, (i) => DateTime.now().year + i - 1)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => onAnioChanged(v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: mes,
                  decoration: const InputDecoration(
                      labelText: 'Mes', border: OutlineInputBorder()),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(meses[m - 1])))
                      .toList(),
                  onChanged: (v) => onMesChanged(v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fecha límite de pago
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: fechaLimite,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) onFechaLimiteChanged(d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha límite de pago',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                  '${fechaLimite.day}/${fechaLimite.month}/${fechaLimite.year}'),
            ),
          ),
        ],
        const SizedBox(height: 32),

        FilledButton.icon(
          onPressed: onSiguiente,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Ver previsualización'),
        ),
      ],
    );
  }
}

// ─── Paso 2: Preview ──────────────────────────────────────────────────────────

class _PasoPreview extends StatelessWidget {
  final _PreviewData? preview;
  final bool cargando;
  final int anio;
  final int mes;
  final List<String> meses;
  final VoidCallback onConfirmar;

  const _PasoPreview({
    super.key,
    required this.preview,
    required this.cargando,
    required this.anio,
    required this.mes,
    required this.meses,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (cargando || preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final p = preview!;
    final sinNada = p.pendientesDeGenerar == 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StepIndicator(paso: 1),
        const SizedBox(height: 24),

        Text('${meses[mes - 1]} $anio',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Resumen numérico
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Cobros a generar',
                value: '${p.pendientesDeGenerar}',
                color: p.pendientesDeGenerar > 0 ? AppColors.ok : cs.onSurfaceVariant,
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Ya generados',
                value: '${p.yaGenerados}',
                color: cs.onSurfaceVariant,
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monto total estimado',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                Text(
                  '\$${_fmt(p.montoTotalEstimado)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Advertencias
        if (p.advertencias.isNotEmpty) ...[
          ...p.advertencias.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgOrange,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.orange)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Breakdown por tipo y periodicidad
        if (p.grupos.isNotEmpty) ...[
          Text('Detalle por tipo',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  fontSize: 13)),
          const SizedBox(height: 8),
          ...p.grupos.map((g) => _FilaGrupo(grupo: g)),
          const SizedBox(height: 16),
        ],

        // Timeline de recurrencia
        _TimelinePeriodicidad(grupos: p.grupos, mesActual: mes),
        const SizedBox(height: 32),

        if (sinNada)
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No hay cobros pendientes — Volver'),
          )
        else
          FilledButton.icon(
            onPressed: onConfirmar,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
                'Generar ${p.pendientesDeGenerar} cobros · \$${_fmt(p.montoTotalEstimado)}'),
          ),
      ],
    );
  }
}

// ─── Paso 3: Generando ────────────────────────────────────────────────────────

class _PasoGenerando extends StatelessWidget {
  final bool creandoPeriodo;
  const _PasoGenerando({super.key, required this.creandoPeriodo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            creandoPeriodo ? 'Abriendo período...' : 'Generando cobros...',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'No cierres esta pantalla.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int paso; // 0, 1, 2
  const _StepIndicator({required this.paso});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const steps = ['Período', 'Previsualización', 'Confirmar'];
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i == paso;
        final done = i < paso;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.ok
                            : active
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? cs.primary : cs.onSurfaceVariant,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Divider(
                    color: i < paso ? AppColors.ok : cs.outlineVariant,
                    thickness: 1.5,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaGrupo extends StatelessWidget {
  final _GrupoDetalle grupo;
  const _FilaGrupo({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (badgeLabel, badgeColor, badgeBg) = switch (grupo.periodicidad) {
      'MENSUAL'    => ('Mensual',    AppColors.blue,   AppColors.bgBlue),
      'TRIMESTRAL' => ('Trimestral', AppColors.teal,   AppColors.bgTeal),
      'SEMESTRAL'  => ('Semestral',  AppColors.orange, AppColors.bgOrange),
      'ANUAL'      => ('Anual',      AppColors.purple, AppColors.bgPurple),
      _            => ('?',          AppColors.blue,   AppColors.bgBlue),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(4)),
            child: Text(badgeLabel,
                style: TextStyle(
                    fontSize: 10, color: badgeColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${grupo.nombreTipo} · ${grupo.cantidad} unid.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text('\$${_fmt(grupo.subtotal)}',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}

/// Muestra un mini-calendario de los próximos 12 meses indicando en cuáles
/// aplica cada tipo de cuota según su periodicidad.
class _TimelinePeriodicidad extends StatelessWidget {
  final List<_GrupoDetalle> grupos;
  final int mesActual;
  const _TimelinePeriodicidad(
      {required this.grupos, required this.mesActual});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (grupos.isEmpty) return const SizedBox.shrink();

    // Agrupar periodicidades únicas
    final periodicidades = grupos.map((g) => g.periodicidad).toSet();
    final abrevMeses = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    bool aplicaEsteMes(String periodicidad, int offsetMes) {
      return switch (periodicidad) {
        'MENSUAL'    => true,
        'TRIMESTRAL' => offsetMes % 3 == 0,
        'SEMESTRAL'  => offsetMes % 6 == 0,
        'ANUAL'      => offsetMes == 0,
        _            => true,
      };
    }

    Color colorPeriodicidad(String p) => switch (p) {
          'MENSUAL'    => AppColors.blue,
          'TRIMESTRAL' => AppColors.teal,
          'SEMESTRAL'  => AppColors.orange,
          'ANUAL'      => AppColors.purple,
          _            => AppColors.blue,
        };

    return Card(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_view_month, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Calendario de recurrencia (próximos 12 meses)',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...periodicidades.map((perio) {
              final color = colorPeriodicidad(perio);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        perio[0] + perio.substring(1).toLowerCase(),
                        style:
                            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(12, (i) {
                          final mesIdx = (mesActual - 1 + i) % 12;
                          final aplica = aplicaEsteMes(perio, i);
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: aplica ? color : Colors.transparent,
                                    border: Border.all(
                                        color: aplica
                                            ? color
                                            : cs.outlineVariant,
                                        width: 1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: i == 0
                                      ? Center(
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: aplica
                                                  ? Colors.white
                                                  : cs.outlineVariant,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 2),
                                Text(abrevMeses[mesIdx],
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) => v
    .toStringAsFixed(0)
    .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
