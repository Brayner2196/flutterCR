import 'package:flutter/material.dart';
import '../../../../shared/utils/mensaje_operacion.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/configuracion_plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';
import 'package:flutter_residential/shared/widgets/panel_tiles.dart';

class AdminConfigPlanPagoScreen extends StatefulWidget {
  const AdminConfigPlanPagoScreen({super.key});

  @override
  State<AdminConfigPlanPagoScreen> createState() =>
      _AdminConfigPlanPagoScreenState();
}

class _AdminConfigPlanPagoScreenState
    extends State<AdminConfigPlanPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maxCuotasCtrl = TextEditingController();
  final _recargoCtrl = TextEditingController();
  final _abonoCtrl = TextEditingController();
  final _graciaCtrl = TextEditingController();
  final _deudaMinCtrl = TextEditingController();
  final _moraMinCtrl = TextEditingController();
  final _esperaIncumplimientoCtrl = TextEditingController();
  final _maxAcuerdosAnioCtrl = TextEditingController();

  // Sin `late`: el primer frame puede pintarse antes de que llegue la
  // configuración, y un `late` sin asignar revienta la pantalla.
  bool _activo = false;
  bool _recargoActivo = false;
  bool _moraCongelada = false;
  bool _aprobacionAuto = false;
  String _baseCalculoAbono = 'DEUDA';

  // Condiciones de elegibilidad (toggle + valor)
  bool _exigeDeudaMinima = false;
  bool _exigeMoraMinima = false;
  bool _bloqueaConAcuerdoVigente = true;
  bool _bloqueaTrasIncumplimiento = false;
  bool _limitaAcuerdosPorAnio = false;
  bool _restringeConceptos = false;
  Set<String> _conceptos = {};

  bool _guardando = false;

  /// Conceptos que pueden entrar a un acuerdo. ACUERDO_PAGO queda fuera a
  /// propósito: refinanciar las cuotas de un acuerdo dentro de otro encadena
  /// reestructuraciones sobre la misma plata.
  static const _conceptosDisponibles = <String, String>{
    'ADMINISTRACION': 'Administración',
    'PARQUEADERO': 'Parqueadero',
    'ZONA_COMUN': 'Zona común',
    'MULTA': 'Multa',
    'SANCION': 'Sanción',
    'OTRO': 'Otro',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<PlanPagoProvider>().cargarConfigAdmin();
      _initFromConfig(context.read<PlanPagoProvider>().config);
    });
  }

  void _initFromConfig(ConfiguracionPlanPagoModel cfg) {
    setState(() {
      _activo = cfg.activo;
      _recargoActivo = cfg.recargoFraccionamiento;
      _moraCongelada = cfg.moraCongeladaDurantePlan;
      _aprobacionAuto = cfg.aprobacionAutomatica;
      _baseCalculoAbono = cfg.baseCalculoAbono;
      _maxCuotasCtrl.text = cfg.maxCuotas.toString();
      _recargoCtrl.text =
          cfg.porcentajeRecargo > 0 ? cfg.porcentajeRecargo.toString() : '';
      _abonoCtrl.text = cfg.porcentajeAbonoInicial > 0
          ? cfg.porcentajeAbonoInicial.toString()
          : '';
      _graciaCtrl.text = cfg.diasGraciaInicial.toString();

      _exigeDeudaMinima = cfg.exigeDeudaMinima;
      _deudaMinCtrl.text = cfg.montoDeudaMinima > 0
          ? cfg.montoDeudaMinima.toStringAsFixed(0)
          : '';
      _exigeMoraMinima = cfg.exigeMoraMinima;
      _moraMinCtrl.text =
          cfg.diasMoraMinima > 0 ? cfg.diasMoraMinima.toString() : '';
      _bloqueaConAcuerdoVigente = cfg.bloqueaConAcuerdoVigente;
      _bloqueaTrasIncumplimiento = cfg.bloqueaTrasIncumplimiento;
      _esperaIncumplimientoCtrl.text = cfg.diasEsperaTrasIncumplimiento > 0
          ? cfg.diasEsperaTrasIncumplimiento.toString()
          : '';
      _limitaAcuerdosPorAnio = cfg.limitaAcuerdosPorAnio;
      _maxAcuerdosAnioCtrl.text = cfg.maxAcuerdosPorAnio.toString();
      _restringeConceptos = cfg.restringeConceptos;
      _conceptos = cfg.conceptosElegibles.toSet();
    });
  }

  double _numero(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  int _entero(TextEditingController c, {int porDefecto = 0}) =>
      int.tryParse(c.text.trim()) ?? porDefecto;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final nuevo = ConfiguracionPlanPagoModel(
      activo: _activo,
      maxCuotas: _entero(_maxCuotasCtrl, porDefecto: 3),
      porcentajeAbonoInicial: _numero(_abonoCtrl),
      diasGraciaInicial: _entero(_graciaCtrl),
      baseCalculoAbono: _baseCalculoAbono,
      recargoFraccionamiento: _recargoActivo,
      porcentajeRecargo: _recargoActivo ? _numero(_recargoCtrl) : 0,
      moraCongeladaDurantePlan: _moraCongelada,
      aprobacionAutomatica: _aprobacionAuto,
      exigeDeudaMinima: _exigeDeudaMinima,
      montoDeudaMinima: _exigeDeudaMinima ? _numero(_deudaMinCtrl) : 0,
      exigeMoraMinima: _exigeMoraMinima,
      diasMoraMinima: _exigeMoraMinima ? _entero(_moraMinCtrl) : 0,
      bloqueaConAcuerdoVigente: _bloqueaConAcuerdoVigente,
      bloqueaTrasIncumplimiento: _bloqueaTrasIncumplimiento,
      diasEsperaTrasIncumplimiento:
          _bloqueaTrasIncumplimiento ? _entero(_esperaIncumplimientoCtrl) : 0,
      limitaAcuerdosPorAnio: _limitaAcuerdosPorAnio,
      maxAcuerdosPorAnio:
          _limitaAcuerdosPorAnio ? _entero(_maxAcuerdosAnioCtrl, porDefecto: 1) : 1,
      restringeConceptos: _restringeConceptos,
      conceptosElegibles: _restringeConceptos ? _conceptos.toList() : const [],
    );

    try {
      final provider = context.read<PlanPagoProvider>();
      final guardada = await provider.guardarConfig(nuevo);
      if (!mounted) return;
      if (!guardada) {
        MensajeOperacion.error(
            context, 'No se pudo guardar la configuración', provider.error);
        return;
      }
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Configuración guardada'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _maxCuotasCtrl.dispose();
    _recargoCtrl.dispose();
    _abonoCtrl.dispose();
    _graciaCtrl.dispose();
    _deudaMinCtrl.dispose();
    _moraMinCtrl.dispose();
    _esperaIncumplimientoCtrl.dispose();
    _maxAcuerdosAnioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlanPagoProvider>();

    if (p.loading && p.config.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acuerdos de pago')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar acuerdos de pago')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Módulo activo ────────────────────────────────────
            _SwitchTile(
              titulo: 'Módulo habilitado',
              subtitulo: _activo
                  ? 'Los residentes pueden solicitar acuerdos de pago'
                  : 'Módulo desactivado — no se aceptan solicitudes',
              valor: _activo,
              onChanged: (v) => setState(() => _activo = v),
            ),
            const SizedBox(height: 16),

            // ── Máximo de cuotas ─────────────────────────────────
            _SectionLabel('Número máximo de cuotas'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxCuotasCtrl,
              decoration: _deco('Ej: 3, 6, 12', Icons.view_week_outlined),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                final n = int.tryParse(v);
                if (n == null || n < 1 || n > 24) {
                  return 'Ingresa un valor entre 1 y 24';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Pago inicial ─────────────────────────────────────
            _SectionLabel('Pago inicial para celebrar el acuerdo'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _abonoCtrl,
              decoration: _deco('% del pago inicial (ej: 40)', Icons.percent),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // 0 = sin inicial
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n < 0) return 'Ingresa un porcentaje válido';
                if (n > 99.99) {
                  return 'Debe ser menor a 100: algo tiene que quedar diferido';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _graciaCtrl,
              decoration: _deco(
                  'Días de gracia para pagarlo (0 = el mismo día)',
                  Icons.event_available_outlined),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 0 || n > 90) return 'Entre 0 y 90 días';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Si el pago inicial no entra dentro del plazo, el acuerdo queda '
              'incumplido: sus cobros se anulan y la deuda original vuelve.',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // ── Recargo por fraccionamiento ───────────────────────
            _SwitchTile(
              titulo: 'Recargo por fraccionamiento',
              subtitulo: _recargoActivo
                  ? 'Se aplica un % adicional sobre la deuda'
                  : 'Sin recargo adicional',
              valor: _recargoActivo,
              onChanged: (v) => setState(() => _recargoActivo = v),
            ),
            if (_recargoActivo) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _recargoCtrl,
                decoration: _deco('% recargo (ej: 5)', Icons.percent),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (!_recargoActivo) return null;
                  if (v == null || v.isEmpty) return 'Ingresa el porcentaje';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),

            // ── Base de cálculo del pago inicial ──────────────────
            // Solo tiene efecto con recargo: sin él las dos opciones dan lo mismo.
            if (_recargoActivo) ...[
              _SectionLabel('El % del pago inicial se calcula sobre'),
              const SizedBox(height: 8),
              _OpcionSelector(
                opciones: const [
                  _Opcion(
                    valor: false,
                    titulo: 'Solo la deuda',
                    subtitulo: 'El recargo se difiere en las cuotas',
                    icono: Icons.account_balance_wallet_outlined,
                    color: AppColors.blue,
                  ),
                  _Opcion(
                    valor: true,
                    titulo: 'Deuda + recargo',
                    subtitulo: 'El pago inicial incluye su parte del recargo',
                    icono: Icons.add_card_outlined,
                    color: AppColors.warning,
                  ),
                ],
                seleccionado: _baseCalculoAbono == 'DEUDA_MAS_RECARGO',
                onChanged: (v) => setState(() =>
                    _baseCalculoAbono = v ? 'DEUDA_MAS_RECARGO' : 'DEUDA'),
              ),
              const SizedBox(height: 20),
            ],

            // ── Comportamiento de mora ────────────────────────────
            _SectionLabel('Mora durante el plan'),
            const SizedBox(height: 8),
            _OpcionSelector(
              opciones: const [
                _Opcion(
                  valor: false,
                  titulo: 'Mora continúa',
                  subtitulo:
                      'La mora sigue acumulando durante el plan activo',
                  icono: Icons.trending_up,
                  color: AppColors.warning,
                ),
                _Opcion(
                  valor: true,
                  titulo: 'Mora congelada',
                  subtitulo:
                      'La mora se detiene mientras el plan esté activo',
                  icono: Icons.ac_unit_outlined,
                  color: AppColors.blue,
                ),
              ],
              seleccionado: _moraCongelada,
              onChanged: (v) => setState(() => _moraCongelada = v),
            ),
            const SizedBox(height: 20),

            // ── Aprobación ────────────────────────────────────────
            _SectionLabel('Aprobación de solicitudes'),
            const SizedBox(height: 8),
            _OpcionSelector(
              opciones: const [
                _Opcion(
                  valor: false,
                  titulo: 'Manual',
                  subtitulo: 'El admin revisa y aprueba cada solicitud',
                  icono: Icons.person_outlined,
                  color: AppColors.blue,
                ),
                _Opcion(
                  valor: true,
                  titulo: 'Automática',
                  subtitulo:
                      'Las solicitudes se aprueban automáticamente si cumplen las reglas',
                  icono: Icons.bolt_outlined,
                  color: AppColors.ok,
                ),
              ],
              seleccionado: _aprobacionAuto,
              onChanged: (v) => setState(() => _aprobacionAuto = v),
            ),
            const SizedBox(height: 32),

            // ── Condiciones para poder solicitar ──────────────────
            // Cada condición se evalúa solo si su toggle está encendido: un
            // valor en cero significaría a la vez "sin mínimo" y "mínimo cero".
            _SectionLabel('Condiciones para poder solicitar'),
            const SizedBox(height: 8),

            _SwitchTile(
              titulo: 'Deuda mínima',
              subtitulo: _exigeDeudaMinima
                  ? 'Solo se puede pedir con una deuda igual o mayor'
                  : 'Cualquier monto de deuda puede reestructurarse',
              valor: _exigeDeudaMinima,
              onChanged: (v) => setState(() => _exigeDeudaMinima = v),
            ),
            if (_exigeDeudaMinima) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _deudaMinCtrl,
                decoration: _deco('Monto mínimo (ej: 500000)',
                    Icons.attach_money_outlined),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_exigeDeudaMinima) return null;
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Ingresa un monto mayor a 0';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),

            _SwitchTile(
              titulo: 'Días mínimos de mora',
              subtitulo: _exigeMoraMinima
                  ? 'Se exige tener al menos un cobro con esa mora'
                  : 'No se exige mora previa',
              valor: _exigeMoraMinima,
              onChanged: (v) => setState(() => _exigeMoraMinima = v),
            ),
            if (_exigeMoraMinima) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _moraMinCtrl,
                decoration:
                    _deco('Días de mora (ej: 30)', Icons.schedule_outlined),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_exigeMoraMinima) return null;
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Ingresa un número de días';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),

            _SwitchTile(
              titulo: 'Un acuerdo a la vez',
              subtitulo: _bloqueaConAcuerdoVigente
                  ? 'No se puede pedir otro con uno pendiente o activo'
                  : 'Se permiten acuerdos simultáneos',
              valor: _bloqueaConAcuerdoVigente,
              onChanged: (v) => setState(() => _bloqueaConAcuerdoVigente = v),
            ),
            const SizedBox(height: 14),

            _SwitchTile(
              titulo: 'Espera tras un incumplimiento',
              subtitulo: _bloqueaTrasIncumplimiento
                  ? 'Debe pasar un tiempo antes de volver a solicitar'
                  : 'Puede volver a solicitar de inmediato',
              valor: _bloqueaTrasIncumplimiento,
              onChanged: (v) => setState(() => _bloqueaTrasIncumplimiento = v),
            ),
            if (_bloqueaTrasIncumplimiento) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _esperaIncumplimientoCtrl,
                decoration: _deco(
                    'Días de espera (ej: 90)', Icons.hourglass_bottom_outlined),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_bloqueaTrasIncumplimiento) return null;
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Ingresa un número de días';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),

            _SwitchTile(
              titulo: 'Límite de acuerdos por año',
              subtitulo: _limitaAcuerdosPorAnio
                  ? 'Se cuentan los acuerdos celebrados en el año calendario'
                  : 'Sin límite anual',
              valor: _limitaAcuerdosPorAnio,
              onChanged: (v) => setState(() => _limitaAcuerdosPorAnio = v),
            ),
            if (_limitaAcuerdosPorAnio) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _maxAcuerdosAnioCtrl,
                decoration: _deco('Máximo por año (ej: 1)',
                    Icons.confirmation_number_outlined),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_limitaAcuerdosPorAnio) return null;
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1) return 'Debe ser al menos 1';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),

            _SwitchTile(
              titulo: 'Restringir conceptos',
              subtitulo: _restringeConceptos
                  ? 'Solo entran al acuerdo los conceptos marcados'
                  : 'Entra toda la deuda del residente',
              valor: _restringeConceptos,
              onChanged: (v) => setState(() => _restringeConceptos = v),
            ),
            if (_restringeConceptos) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conceptosDisponibles.entries.map((e) {
                  final activo = _conceptos.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
                    selected: activo,
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _conceptos.add(e.key);
                      } else {
                        _conceptos.remove(e.key);
                      }
                    }),
                  );
                }).toList(),
              ),
              if (_conceptos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Selecciona al menos un concepto',
                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ),
            ],
            const SizedBox(height: 32),

            // ── Botón guardar ─────────────────────────────────────
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Guardar configuración'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 0.5,
        ));
  }
}

class _SwitchTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PanelTiles(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: cs.surfaceContainerHighest,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitulo,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        value: valor,
        onChanged: onChanged,
      ),
    );
  }
}

class _Opcion {
  final bool valor;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _Opcion({
    required this.valor,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });
}

class _OpcionSelector extends StatelessWidget {
  final List<_Opcion> opciones;
  final bool seleccionado;
  final ValueChanged<bool> onChanged;

  const _OpcionSelector({
    required this.opciones,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: opciones.map((op) {
        final activo = op.valor == seleccionado;
        final cs = Theme.of(context).colorScheme;
        return GestureDetector(
          onTap: () => onChanged(op.valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activo
                  ? op.color.withValues(alpha: 0.08)
                  : cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: activo ? op.color : cs.outline, width: activo ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: activo
                        ? op.color.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(op.icono,
                      size: 18,
                      color: activo ? op.color : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(op.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: activo ? op.color : cs.onSurface,
                          )),
                      Text(op.subtitulo,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (activo)
                  Icon(Icons.check_circle, size: 18, color: op.color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
