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
  final List<_PropiedadDetalle> propiedades;

  const _GrupoDetalle({
    required this.nombreTipo,
    required this.periodicidad,
    required this.cantidad,
    required this.montoPorUnidad,
    required this.subtotal,
    required this.propiedades,
  });

  factory _GrupoDetalle.fromJson(Map<String, dynamic> j) => _GrupoDetalle(
        nombreTipo: j['nombreTipo'] as String,
        periodicidad: j['periodicidad'] as String,
        cantidad: j['cantidad'] as int,
        montoPorUnidad: (j['montoPorUnidad'] as num).toDouble(),
        subtotal: (j['subtotal'] as num).toDouble(),
        propiedades: ((j['propiedades'] as List?) ?? [])
            .map((p) => _PropiedadDetalle.fromJson(p))
            .toList(),
      );
}

class _PropiedadDetalle {
  final int propiedadId;
  final String pathTexto;
  final double monto;

  const _PropiedadDetalle({
    required this.propiedadId,
    required this.pathTexto,
    required this.monto,
  });

  factory _PropiedadDetalle.fromJson(Map<String, dynamic> j) =>
      _PropiedadDetalle(
        propiedadId: j['propiedadId'] as int,
        pathTexto: (j['pathTexto'] ?? '') as String,
        monto: (j['monto'] as num).toDouble(),
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
                  initialValue: anio,
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
                  initialValue: mes,
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
          icon: Icon(Icons.preview_outlined, color: cs.onPrimaryContainer),
          label: Text('Ver previsualización', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
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
    if (cargando || preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final p = preview!;
    final sinNada = p.pendientesDeGenerar == 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StepIndicator(paso: 1),
              const SizedBox(height: AppSpacing.lg),

              // Tarjeta hero: período + monto total + nº de cobros
              _HeroResumen(
                periodo: '${meses[mes - 1]} $anio',
                pendientes: p.pendientesDeGenerar,
                montoTotal: p.montoTotalEstimado,
              ),
              const SizedBox(height: AppSpacing.md),

              // Cobertura de propiedades
              _CoberturaPropiedades(
                total: p.totalPropiedades,
                generados: p.yaGenerados,
                pendientes: p.pendientesDeGenerar,
              ),
              const SizedBox(height: AppSpacing.md),

              // Advertencias
              if (p.advertencias.isNotEmpty) ...[
                ...p.advertencias.map((a) => _AvisoCard(texto: a)),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Detalle por tipo de propiedad
              if (p.grupos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 2, bottom: AppSpacing.sm, top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.tune,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Detalle por tipo de propiedad',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ],
                  ),
                ),
                ...p.grupos.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _DetalleGrupoCard(grupo: g),
                    )),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),

        // Footer de acción fijo
        _FooterGenerar(
          sinNada: sinNada,
          pendientes: p.pendientesDeGenerar,
          montoTotal: p.montoTotalEstimado,
          onConfirmar: onConfirmar,
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
    const steps = ['Período', 'Vista Previa', 'Confirmar'];
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
                                  color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
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

/// Etiquetas y colores de cada periodicidad, centralizados para reutilizar.
({String label, Color color, Color bg}) _periodicidadStyle(String p) =>
    switch (p) {
      'MENSUAL' => (label: 'Mensual', color: AppColors.blue, bg: AppColors.bgBlue),
      'TRIMESTRAL' =>
        (label: 'Trimestral', color: AppColors.teal, bg: AppColors.bgTeal),
      'SEMESTRAL' =>
        (label: 'Semestral', color: AppColors.orange, bg: AppColors.bgOrange),
      'ANUAL' =>
        (label: 'Anual', color: AppColors.purple, bg: AppColors.bgPurple),
      _ => (label: p, color: AppColors.blue, bg: AppColors.bgBlue),
    };

/// Tarjeta hero del preview: período, nº de cobros y monto total destacado.
class _HeroResumen extends StatelessWidget {
  final String periodo;
  final int pendientes;
  final double montoTotal;
  const _HeroResumen({
    required this.periodo,
    required this.pendientes,
    required this.montoTotal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activo = pendientes > 0;
    final acento = activo ? AppColors.green : cs.onSurfaceVariant;
    final fondo = activo ? AppColors.bgGreen : cs.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: acento.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, size: 18, color: acento),
              const SizedBox(width: 6),
              Text(periodo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: acento,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Monto total estimado',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text('\$ ${_fmt(montoTotal)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: acento,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 15, color: acento),
              const SizedBox(width: 6),
              Text(
                activo
                    ? '$pendientes cobros por generar'
                    : 'Sin cobros pendientes',
                style: TextStyle(
                    fontSize: 13, color: acento, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cobertura del período: barra de progreso generados vs total + chips.
class _CoberturaPropiedades extends StatelessWidget {
  final int total;
  final int generados;
  final int pendientes;
  const _CoberturaPropiedades({
    required this.total,
    required this.generados,
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progreso = total == 0 ? 0.0 : (generados / total).clamp(0.0, 1.0);
    final pct = (progreso * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cobertura del período',
                    style: Theme.of(context).textTheme.titleSmall),
                Text('$pct%',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: progreso >= 1 ? AppColors.ok : cs.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                    progreso >= 1 ? AppColors.ok : cs.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _MiniStat(
                    icon: Icons.check_circle,
                    color: AppColors.ok,
                    valor: '$generados',
                    label: 'Generados'),
                const SizedBox(width: AppSpacing.sm),
                _MiniStat(
                    icon: Icons.pending_actions,
                    color: pendientes > 0 ? AppColors.orange : cs.onSurfaceVariant,
                    valor: '$pendientes',
                    label: 'Pendientes'),
                const SizedBox(width: AppSpacing.sm),
                _MiniStat(
                    icon: Icons.home_work_outlined,
                    color: cs.onSurfaceVariant,
                    valor: '$total',
                    label: 'Propiedades'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String valor;
  final String label;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.valor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            Text(label,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de aviso/advertencia con estilo coherente.
class _AvisoCard extends StatelessWidget {
  final String texto;
  const _AvisoCard({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.warning,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta detallada de un grupo: tipo, periodicidad, desglose y lista
/// expandible de las propiedades con su path y cobro respectivo.
class _DetalleGrupoCard extends StatefulWidget {
  final _GrupoDetalle grupo;
  const _DetalleGrupoCard({required this.grupo});

  @override
  State<_DetalleGrupoCard> createState() => _DetalleGrupoCardState();
}

class _DetalleGrupoCardState extends State<_DetalleGrupoCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final grupo = widget.grupo;
    final cs = Theme.of(context).colorScheme;
    final estilo = _periodicidadStyle(grupo.periodicidad);
    final hayPropiedades = grupo.propiedades.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: estilo.bg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.apartment, size: 20, color: estilo.color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grupo.nombreTipo,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: estilo.bg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(estilo.label,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: estilo.color,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                Text('\$${_fmt(grupo.subtotal)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        )),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Desglose + toggle de propiedades
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${grupo.cantidad} unid',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                if (hayPropiedades)
                  InkWell(
                    onTap: () => setState(() => _expandido = !_expandido),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expandido
                                ? 'Ocultar'
                                : 'Ver ${grupo.propiedades.length} propiedades',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          Icon(
                            _expandido
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text('Subtotal',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),

            // Lista de propiedades
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expandido
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  ...grupo.propiedades.map((prop) => _FilaPropiedad(
                        prop: prop,
                        color: estilo.color,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila individual de una propiedad: path legible + su cobro.
class _FilaPropiedad extends StatelessWidget {
  final _PropiedadDetalle prop;
  final Color color;
  const _FilaPropiedad({required this.prop, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prop.pathTexto.isEmpty ? 'Propiedad ${prop.propiedadId}' : prop.pathTexto,
              style: const TextStyle(fontSize: 12.5, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('\$${_fmt(prop.monto)}',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
        ],
      ),
    );
  }
}

/// Footer fijo con el resumen y la acción principal de generar.
class _FooterGenerar extends StatelessWidget {
  final bool sinNada;
  final int pendientes;
  final double montoTotal;
  final VoidCallback onConfirmar;
  const _FooterGenerar({
    required this.sinNada,
    required this.pendientes,
    required this.montoTotal,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: sinNada
          ? OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Todo al día — Volver'),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$pendientes cobros',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    Text('\$${_fmt(montoTotal)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: onConfirmar,
                  icon: Icon(Icons.auto_awesome, color: cs.onPrimaryContainer),
                  label: Text('Generar cobros', style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
    );
  }
}

String _fmt(double v) => v
    .toStringAsFixed(0)
    .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
