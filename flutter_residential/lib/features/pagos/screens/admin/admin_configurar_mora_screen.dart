import 'package:flutter/material.dart';
import '../../models/configuracion_mora_model.dart';
import '../../services/mora_service.dart';
import '../../../../shared/theme/app_theme.dart';

class AdminConfigurarMoraScreen extends StatefulWidget {
  const AdminConfigurarMoraScreen({super.key});

  @override
  State<AdminConfigurarMoraScreen> createState() =>
      _AdminConfigurarMoraScreenState();
}

class _AdminConfigurarMoraScreenState extends State<AdminConfigurarMoraScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _cargando = true;
  ConfiguracionMoraModel? _activa;
  List<ConfiguracionMoraModel> _historico = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final activa = await MoraService.obtenerActiva();
      final historico = await MoraService.listarHistorico();
      if (mounted) {
        setState(() {
          _activa = activa;
          _historico = historico;
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirFormulario() async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NuevaMoraSheet(),
    );
    if (guardado == true) await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar mora'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Vigente'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 16),
                  SizedBox(width: 6),
                  Text('Historial'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Nueva config.'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TabVigente(mora: _activa),
                _TabHistorial(historico: _historico),
              ],
            ),
    );
  }
}

// ─── Tab Vigente ──────────────────────────────────────────────────────────────

class _TabVigente extends StatelessWidget {
  final ConfiguracionMoraModel? mora;
  const _TabVigente({required this.mora});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (mora == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_outlined, size: 52, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Sin configuración de mora',
                style: TextStyle(color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Los cobros vencidos no generan recargo.\nToca "Nueva config." para configurar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final esPorcentaje = mora!.tipoCalculo == 'PORCENTAJE';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ── Card principal ─────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        esPorcentaje ? 'PORCENTAJE MENSUAL' : 'MONTO FIJO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.ok,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Activa',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ok,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),

                // Valor principal
                Center(
                  child: esPorcentaje
                      ? RichText(
                          text: TextSpan(
                            style: TextStyle(color: cs.onSurface),
                            children: [
                              TextSpan(
                                text: mora!.porcentajeMensual?.toStringAsFixed(1) ?? '?',
                                style: const TextStyle(
                                    fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: '%',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                              const TextSpan(
                                text: ' / mes',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            style: TextStyle(color: cs.onSurface),
                            children: [
                              const TextSpan(
                                text: '\$',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: _fmt(mora!.montoFijo ?? 0),
                                style: const TextStyle(
                                    fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: ' fijo',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // Días de gracia y vigencia
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: mora!.diasGracia == 0
                          ? 'Sin días de gracia'
                          : '${mora!.diasGracia} días de gracia',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Desde ${_fmtFecha(mora!.fechaVigencia)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Preview de cálculo ─────────────────────────────────────
        _PreviewMora(mora: mora!),
      ],
    );
  }
}

// ─── Preview de cómo se aplica la mora ───────────────────────────────────────

class _PreviewMora extends StatefulWidget {
  final ConfiguracionMoraModel mora;
  const _PreviewMora({required this.mora});

  @override
  State<_PreviewMora> createState() => _PreviewMoraState();
}

class _PreviewMoraState extends State<_PreviewMora> {
  double _montoCobro = 100000;
  int _diasAtraso = 30;

  double get _moraCaculada {
    final mora = widget.mora;
    if (mora.tipoCalculo == 'PORCENTAJE') {
      final pct = mora.porcentajeMensual ?? 0;
      // Aplicar proporcional a los días de atraso (30 días = 1 mes)
      return _montoCobro * (pct / 100) * (_diasAtraso / 30);
    } else {
      return mora.montoFijo ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diasEfectivos =
        (_diasAtraso - widget.mora.diasGracia).clamp(0, 999);
    final aplicaMora = diasEfectivos > 0;

    return Card(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text('Simulador de mora',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.primary)),
              ],
            ),
            const SizedBox(height: 16),

            // Slider monto
            Text('Monto del cobro: \$${_fmt(_montoCobro)}',
                style: const TextStyle(fontSize: 13)),
            Slider(
              value: _montoCobro,
              min: 50000,
              max: 1000000,
              divisions: 19,
              label: '\$${_fmt(_montoCobro)}',
              onChanged: (v) => setState(() => _montoCobro = v),
            ),

            // Slider días
            Text('Días de atraso: $_diasAtraso días',
                style: const TextStyle(fontSize: 13)),
            Slider(
              value: _diasAtraso.toDouble(),
              min: 0,
              max: 120,
              divisions: 24,
              label: '$_diasAtraso días',
              onChanged: (v) => setState(() => _diasAtraso = v.round()),
            ),

            const Divider(),

            // Resultado
            if (!aplicaMora) ...[
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.ok, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dentro del período de gracia (${widget.mora.diasGracia} días). Sin mora.',
                      style: TextStyle(color: AppColors.ok, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mora generada:', style: TextStyle(color: cs.onSurfaceVariant)),
                  Text(
                    '+\$${_fmt(_moraCaculada)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total a pagar:', style: TextStyle(color: cs.onSurfaceVariant)),
                  Text(
                    '\$${_fmt(_montoCobro + _moraCaculada)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              if (widget.mora.diasGracia > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Días efectivos con mora: $diasEfectivos ($_diasAtraso − ${widget.mora.diasGracia} de gracia)',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Historial ────────────────────────────────────────────────────────────

class _TabHistorial extends StatelessWidget {
  final List<ConfiguracionMoraModel> historico;
  const _TabHistorial({required this.historico});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (historico.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Sin historial',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: historico.length,
      itemBuilder: (_, i) {
        final m = historico[i];
        final esPorcentaje = m.tipoCalculo == 'PORCENTAJE';
        final valorStr = esPorcentaje
            ? '${m.porcentajeMensual?.toStringAsFixed(1) ?? '?'}% / mes'
            : '\$${_fmt(m.montoFijo ?? 0)} fijo';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: m.activo ? AppColors.ok : cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < historico.length - 1)
                      Expanded(
                        child: Center(
                          child: Container(
                              width: 1.5, color: cs.outlineVariant),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: m.activo ? cs.surfaceContainer : cs.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  valorStr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: m.activo ? AppColors.ok : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (m.activo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Activa',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.ok,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${m.diasGracia} días gracia',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today_outlined,
                                  size: 12, color: cs.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Text(
                                'Desde ${_fmtFecha(m.fechaVigencia)}',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Formulario nueva configuración de mora ───────────────────────────────────

class _NuevaMoraSheet extends StatefulWidget {
  const _NuevaMoraSheet();

  @override
  State<_NuevaMoraSheet> createState() => _NuevaMoraSheetState();
}

class _NuevaMoraSheetState extends State<_NuevaMoraSheet> {
  final _form = GlobalKey<FormState>();
  final _porcentajeCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _diasGraciaCtrl = TextEditingController(text: '0');
  String _tipoCalculo = 'PORCENTAJE';
  DateTime _fechaVigencia = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _porcentajeCtrl.dispose();
    _montoCtrl.dispose();
    _diasGraciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      String iso(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final body = <String, dynamic>{
        'tipoCalculo': _tipoCalculo,
        'diasGracia': int.parse(_diasGraciaCtrl.text),
        'fechaVigencia': iso(_fechaVigencia),
      };
      if (_tipoCalculo == 'PORCENTAJE') {
        body['porcentajeMensual'] = double.parse(_porcentajeCtrl.text);
      } else {
        body['montoFijo'] = double.parse(_montoCtrl.text);
      }
      await MoraService.crear(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Nueva configuración de mora',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Se desactivará la configuración anterior.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Tipo de cálculo
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'PORCENTAJE',
                    icon: Icon(Icons.percent, size: 16),
                    label: Text('Porcentaje'),
                  ),
                  ButtonSegment(
                    value: 'MONTO_FIJO',
                    icon: Icon(Icons.attach_money, size: 16),
                    label: Text('Monto fijo'),
                  ),
                ],
                selected: {_tipoCalculo},
                onSelectionChanged: (s) => setState(() {
                  _tipoCalculo = s.first;
                  _porcentajeCtrl.clear();
                  _montoCtrl.clear();
                }),
              ),
              const SizedBox(height: 16),

              // Campo según tipo
              if (_tipoCalculo == 'PORCENTAJE')
                TextFormField(
                  controller: _porcentajeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje mensual (%)',
                    hintText: 'Ej: 2.5',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final d = double.tryParse(v);
                    if (d == null) return 'Número inválido';
                    if (d <= 0 || d > 100) return 'Entre 0.01 y 100';
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto fijo de mora',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final d = double.tryParse(v);
                    if (d == null) return 'Número inválido';
                    if (d <= 0) return 'Debe ser mayor a 0';
                    return null;
                  },
                ),
              const SizedBox(height: 12),

              // Días de gracia
              TextFormField(
                controller: _diasGraciaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Días de gracia',
                  hintText: '0 = sin gracia',
                  suffixText: 'días',
                  border: OutlineInputBorder(),
                  helperText:
                      'Días tras el vencimiento antes de aplicar mora.',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final d = int.tryParse(v);
                  if (d == null) return 'Entero';
                  if (d < 0 || d > 60) return 'Entre 0 y 60';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Fecha de vigencia
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaVigencia,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _fechaVigencia = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Vigencia desde',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_fechaVigencia.day.toString().padLeft(2, '0')}/${_fechaVigencia.month.toString().padLeft(2, '0')}/${_fechaVigencia.year}',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Guardar configuración'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(double v) => v
    .toStringAsFixed(0)
    .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

String _fmtFecha(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
