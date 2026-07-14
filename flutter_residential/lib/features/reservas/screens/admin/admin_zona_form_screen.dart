import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/utils/scrollingText.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/reserva_model.dart';
import '../../services/reserva_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Pantalla completa de parametrización de zona común
// Sustituye el antiguo _ZonaFormSheet. Diseño basado en mockup parametrizacion-zona.html
// ═══════════════════════════════════════════════════════════════════════════

class AdminZonaFormScreen extends StatefulWidget {
  final ZonaComunModel? zona; // null = nueva zona

  const AdminZonaFormScreen({super.key, this.zona});

  @override
  State<AdminZonaFormScreen> createState() => _AdminZonaFormScreenState();
}

class _AdminZonaFormScreenState extends State<AdminZonaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  // ── Secciones colapsadas ──────────────────────────────────────────────────
  final Map<String, bool> _expanded = {
    'identidad':     true,
    'aforo':         true,
    'horarios':      true,
    'reglas':        false,
    'aprobacion':    false,
    'costo':         false,
    'restricciones': false,
    'estado':        false,
  };

  // ── Campos del formulario ─────────────────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _aforoCtrl  = TextEditingController();
  final _durMinCtrl = TextEditingController();
  final _durMaxCtrl = TextEditingController();
  final _antMinCtrl = TextEditingController();
  final _antMaxCtrl = TextEditingController();
  final _resSemanCtrl = TextEditingController();
  final _resMesCtrl   = TextEditingController();
  final _cancelHCtrl  = TextEditingController();
  final _tarifaCtrl   = TextEditingController();
  final _depositoCtrl = TextEditingController();
  final _torreCtrl    = TextEditingController();

  String _categoria = 'SALON';
  bool   _usoExclusivo = true;
  int    _bufferLimpieza = 0;
  String _modoAprobacion = 'MANUAL';
  bool   _tieneCosto = false;
  String _modoTarifa = 'POR_HORA';
  bool   _soloPropietarios = false;
  bool   _sinDeudaPendiente = false;
  bool   _activa = true;

  // ── Grupos de horario (variante C) ────────────────────────────────────────
  List<HorarioGrupoModel> _grupos = [];

  @override
  void initState() {
    super.initState();
    final z = widget.zona;
    if (z != null) {
      _nombreCtrl.text  = z.nombre;
      _descCtrl.text    = z.descripcion ?? '';
      _aforoCtrl.text   = z.capacidad.toString();
      _categoria        = z.categoria ?? 'SALON';
      _usoExclusivo     = z.usoExclusivo;
      _bufferLimpieza   = z.bufferLimpiezaMinutos;
      // MIXTA quedó descontinuada (no soportada en backend) → se trata como MANUAL
      _modoAprobacion   = z.modoAprobacion == 'MIXTA' ? 'MANUAL' : z.modoAprobacion;
      _tieneCosto       = z.tieneCosto;
      _modoTarifa       = z.modoTarifa ?? 'POR_HORA';
      _soloPropietarios = z.soloPropietarios;
      _sinDeudaPendiente = z.sinDeudaPendiente;
      _activa           = z.activa;
      _grupos           = List.from(z.horarioGrupos);

      if (z.duracionMinMinutos != null) _durMinCtrl.text = (z.duracionMinMinutos! ~/ 60).toString();
      if (z.duracionMaxMinutos != null) _durMaxCtrl.text = (z.duracionMaxMinutos! ~/ 60).toString();
      if (z.anticipacionMinDias != null) _antMinCtrl.text = z.anticipacionMinDias.toString();
      if (z.anticipacionMaxDias != null) _antMaxCtrl.text = z.anticipacionMaxDias.toString();
      if (z.maxReservasSemana != null) _resSemanCtrl.text = z.maxReservasSemana.toString();
      if (z.maxReservasMes != null) _resMesCtrl.text = z.maxReservasMes.toString();
      if (z.cancelacionHorasAntes != null) _cancelHCtrl.text = z.cancelacionHorasAntes.toString();
      if (z.tarifaMonto != null) _tarifaCtrl.text = z.tarifaMonto!.toStringAsFixed(0);
      if (z.depositoMonto != null) _depositoCtrl.text = z.depositoMonto!.toStringAsFixed(0);
      if (z.soloTorre != null) _torreCtrl.text = z.soloTorre!;
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _descCtrl, _aforoCtrl, _durMinCtrl, _durMaxCtrl,
      _antMinCtrl, _antMaxCtrl, _resSemanCtrl, _resMesCtrl, _cancelHCtrl,
      _tarifaCtrl, _depositoCtrl, _torreCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Porcentaje de completitud ─────────────────────────────────────────────
  int get _completitud {
    int done = 0;
    if (_nombreCtrl.text.isNotEmpty) done++;
    if (_aforoCtrl.text.isNotEmpty) done++;
    if (_grupos.isNotEmpty) done++;
    if (_durMaxCtrl.text.isNotEmpty) done++;
    if (_antMinCtrl.text.isNotEmpty) done++;
    if (!_tieneCosto || _tarifaCtrl.text.isNotEmpty) done++;
    return ((done / 6) * 100).round();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_grupos.isEmpty) {
      _snack('Configura al menos un grupo de horario', isError: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      final body = {
        'nombre':      _nombreCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'categoria':   _categoria,
        'capacidad':   int.tryParse(_aforoCtrl.text) ?? 0,
        'activa':      _activa,
        'usoExclusivo': _usoExclusivo,
        'bufferLimpiezaMinutos': _bufferLimpieza,
        'horarioGrupos': _grupos.map((g) => g.toJson()).toList(),
        if (_durMinCtrl.text.isNotEmpty) 'duracionMinMinutos': (int.parse(_durMinCtrl.text)) * 60,
        if (_durMaxCtrl.text.isNotEmpty) 'duracionMaxMinutos': (int.parse(_durMaxCtrl.text)) * 60,
        if (_antMinCtrl.text.isNotEmpty) 'anticipacionMinDias': int.parse(_antMinCtrl.text),
        if (_antMaxCtrl.text.isNotEmpty) 'anticipacionMaxDias': int.parse(_antMaxCtrl.text),
        if (_resSemanCtrl.text.isNotEmpty) 'maxReservasSemana': int.parse(_resSemanCtrl.text),
        if (_resMesCtrl.text.isNotEmpty)   'maxReservasMes':    int.parse(_resMesCtrl.text),
        if (_cancelHCtrl.text.isNotEmpty)  'cancelacionHorasAntes': int.parse(_cancelHCtrl.text),
        'modoAprobacion': _modoAprobacion,
        'requiereAprobacion': _modoAprobacion != 'AUTOMATICA',
        'tieneCosto': _tieneCosto,
        if (_tieneCosto) 'modoTarifa': _modoTarifa,
        if (_tieneCosto && _tarifaCtrl.text.isNotEmpty)
          'tarifaMonto': double.parse(_tarifaCtrl.text),
        if (_tieneCosto && _depositoCtrl.text.isNotEmpty)
          'depositoMonto': double.parse(_depositoCtrl.text),
        'soloPropietarios':  _soloPropietarios,
        'sinDeudaPendiente': _sinDeudaPendiente,
        if (_torreCtrl.text.isNotEmpty) 'soloTorre': _torreCtrl.text.trim(),
      };

      if (widget.zona == null) {
        await ReservaService.crearZona(body);
      } else {
        await ReservaService.actualizarZona(widget.zona!.id, body);
      }

      if (mounted) {
        _snack(widget.zona == null ? 'Zona creada' : 'Zona actualizada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.ok,
    ));
  }

  void _toggle(String key) => setState(() => _expanded[key] = !(_expanded[key] ?? false));

  @override
  Widget build(BuildContext context) {
    final esNueva = widget.zona == null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(esNueva ? 'Nueva zona común' : 'Editar zona'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
          children: [
            // Hero de estado
            _HeroEstado(
              nombre: _nombreCtrl.text.isEmpty ? 'Sin nombre' : _nombreCtrl.text,
              completitud: _completitud,
              activa: _activa,
              numGrupos: _grupos.length,
              aforo: int.tryParse(_aforoCtrl.text) ?? 0,
              tieneCosto: _tieneCosto,
              tarifa: _tarifaCtrl.text,
              modoTarifa: _modoTarifa,
            ),
            const SizedBox(height: 12),

            // 1 · Identidad
            _SectionCard(
              icon: Icons.sell_outlined,
              iconColor: AppColors.blue,
              title: 'Identidad',
              subtitle: 'Nombre, categoría y descripción',
              complete: _nombreCtrl.text.isNotEmpty,
              expanded: _expanded['identidad']!,
              onTap: () => _toggle('identidad'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoriaSelector(
                    selected: _categoria,
                    onChanged: (v) => setState(() => _categoria = v),
                  ),
                  const SizedBox(height: 14),
                  _Label('Nombre'),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Salón social principal',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  _Label('Descripción', hint: 'Opcional · visible al residente'),
                  TextFormField(
                    controller: _descCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Describe el espacio, equipamiento, normas básicas...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // 2 · Aforo y modo de uso
            _SectionCard(
              icon: Icons.groups_outlined,
              iconColor: AppColors.purple,
              title: 'Aforo y modo de uso',
              subtitle: 'Capacidad, uso exclusivo y buffer de limpieza',
              complete: _aforoCtrl.text.isNotEmpty,
              expanded: _expanded['aforo']!,
              onTap: () => _toggle('aforo'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Aforo máximo de personas'),
                  TextFormField(
                    controller: _aforoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'personas',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _Label('Modo de uso'),
                  _ModoUsoSelector(
                    exclusivo: _usoExclusivo,
                    onChanged: (v) => setState(() => _usoExclusivo = v),
                  ),
                  const SizedBox(height: 16),
                  _Label('Buffer de limpieza entre reservas'),
                  _ChipSelector<int>(
                    options: const [0, 15, 30, 60],
                    labels: const ['Sin buffer', '15 min', '30 min', '1 hora'],
                    selected: _bufferLimpieza,
                    color: AppColors.purple,
                    onChanged: (v) => setState(() => _bufferLimpieza = v),
                  ),
                ],
              ),
            ),

            // 3 · Horarios por grupos
            _SectionCard(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.orange,
              title: 'Horarios disponibles',
              subtitle: _grupos.isEmpty
                  ? 'Sin grupos configurados'
                  : '${_grupos.length} grupo${_grupos.length != 1 ? 's' : ''} · ${_grupos.fold(0, (s, g) => s + g.franjas.length)} franja${_grupos.fold(0, (s, g) => s + g.franjas.length) != 1 ? 's' : ''}',
              complete: _grupos.isNotEmpty,
              expanded: _expanded['horarios']!,
              onTap: () => _toggle('horarios'),
              child: _EditorHorarioGrupos(
                grupos: _grupos,
                onChanged: (grupos) => setState(() => _grupos = grupos),
              ),
            ),

            // 4 · Reglas de reserva
            _SectionCard(
              icon: Icons.tune_outlined,
              iconColor: AppColors.teal,
              title: 'Reglas de reserva',
              subtitle: 'Duración, anticipación, cuotas y cancelación',
              expanded: _expanded['reglas']!,
              onTap: () => _toggle('reglas'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Duración mín. (horas)'),
                      TextFormField(
                        controller: _durMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '1'),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Duración máx. (horas)'),
                      TextFormField(
                        controller: _durMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '4'),
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Anticipación mín. (días)'),
                      TextFormField(
                        controller: _antMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '1'),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Anticipación máx. (días)'),
                      TextFormField(
                        controller: _antMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '30'),
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Máx. por residente/semana'),
                      TextFormField(
                        controller: _resSemanCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '2'),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Máx. por residente/mes'),
                      TextFormField(
                        controller: _resMesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '4'),
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  _Label('Cancelación permitida hasta (horas antes)'),
                  TextFormField(
                    controller: _cancelHCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'horas antes',
                      border: OutlineInputBorder(),
                      hintText: '24',
                    ),
                  ),
                ],
              ),
            ),

            // 5 · Aprobación
            _SectionCard(
              icon: Icons.auto_awesome_outlined,
              iconColor: AppColors.green,
              title: 'Modo de aprobación',
              subtitle: _modoAprobacionLabel(_modoAprobacion),
              expanded: _expanded['aprobacion']!,
              onTap: () => _toggle('aprobacion'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Modo'),
                  _SegmentedRow(
                    options: const ['AUTOMATICA', 'MANUAL'],
                    labels:  const ['Automática', 'Manual'],
                    selected: _modoAprobacion,
                    color: AppColors.green,
                    onChanged: (v) => setState(() => _modoAprobacion = v),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.okSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: AppColors.ok, width: 3)),
                    ),
                    child: Text(
                      _modoAprobacion == 'AUTOMATICA'
                          ? 'Toda reserva se aprueba automáticamente al crearla.'
                          : 'Toda reserva requiere aprobación manual del administrador.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.ok, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // 6 · Costo
            _SectionCard(
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF8C6D00),
              title: 'Costo',
              subtitle: _tieneCosto ? 'Zona con tarifa configurada' : 'Zona gratuita',
              expanded: _expanded['costo']!,
              onTap: () => _toggle('costo'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ToggleRow(
                    icon: Icons.attach_money,
                    title: 'Esta zona tiene costo',
                    subtitle: 'Se carga al estado de cuenta al aprobar',
                    value: _tieneCosto,
                    color: const Color.fromRGBO(140, 109, 0, 1),
                    onChanged: (v) => setState(() => _tieneCosto = v),
                  ),
                  
                  if (_tieneCosto) ...[
                    const SizedBox(height: 12),
                    _Label('Tipo de tarifa'),
                    _SegmentedRow(
                      options: const ['FIJA', 'POR_HORA', 'POR_PERSONA'],
                      labels:  const ['Monto fijo', 'Por hora', 'Por persona'],
                      selected: _modoTarifa,
                      color: const Color(0xFF8C6D00),
                      onChanged: (v) => setState(() => _modoTarifa = v),
                    ),
                    const SizedBox(height: 12),
                    _Label('Tarifa'),
                    TextFormField(
                      controller: _tarifaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '\$',
                        suffixText: _modoTarifa == 'POR_HORA'
                            ? '/ hora'
                            : _modoTarifa == 'POR_PERSONA'
                                ? '/ persona'
                                : '',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Label('Depósito reembolsable', hint: 'Liberado 48h luego si no hay reporte' ),
                    TextFormField(
                      controller: _depositoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 7 · Restricciones
            _SectionCard(
              icon: Icons.shield_outlined,
              iconColor: AppColors.danger,
              title: 'Quién puede reservar',
              subtitle: 'Restricciones de acceso',
              expanded: _expanded['restricciones']!,
              onTap: () => _toggle('restricciones'),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.lock_outline,
                    title: 'Sólo propietarios',
                    subtitle: 'Los inquilinos no podrán reservar',
                    value: _soloPropietarios,
                    color: AppColors.danger,
                    onChanged: (v) => setState(() => _soloPropietarios = v),
                  ),
                  _ToggleRow(
                    icon: Icons.check_circle_outline,
                    title: 'Sin deuda pendiente',
                    subtitle: 'Bloquea si tiene cobros vencidos',
                    value: _sinDeudaPendiente,
                    color: AppColors.danger,
                    onChanged: (v) => setState(() => _sinDeudaPendiente = v),
                    isLast: false,
                  ),
                  const SizedBox(height: 12),
                  _Label('Restringir a torre / bloque', hint: 'Opcional'),
                  TextFormField(
                    controller: _torreCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Torre A, Bloque 2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // 8 · Estado
            _SectionCard(
              icon: Icons.toggle_on_outlined,
              iconColor: Colors.grey,
              title: 'Estado de la zona',
              subtitle: _activa ? 'Activa · visible para residentes' : 'Inactiva · oculta para residentes',
              expanded: _expanded['estado']!,
              onTap: () => _toggle('estado'),
              child:  _ToggleRow(
                icon:Icons.check_circle_outline,
                color: AppColors.ok,
                title: 'Zona activa',
                subtitle: 'Los residentes pueden ver y reservar esta zona',
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),
            ),
          ],
        ),
      ),

      // Footer sticky
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 14, right: 14, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.zona == null ? 'Crear zona' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modoAprobacionLabel(String modo) {
    switch (modo) {
      case 'AUTOMATICA': return 'Aprobación automática';
      case 'MANUAL':     return 'Aprobación manual';
      case 'MIXTA':      return 'Aprobación mixta con reglas';
      default:           return modo;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Hero de estado — banner oscuro con progreso y mini-KPIs
// ═══════════════════════════════════════════════════════════════════════════

class _HeroEstado extends StatelessWidget {
  final String nombre;
  final int completitud;
  final bool activa;
  final int numGrupos;
  final int aforo;
  final bool tieneCosto;
  final String tarifa;
  final String modoTarifa;

  const _HeroEstado({
    required this.nombre,
    required this.completitud,
    required this.activa,
    required this.numGrupos,
    required this.aforo,
    required this.tieneCosto,
    required this.tarifa,
    required this.modoTarifa,
  });

  @override
  Widget build(BuildContext context) {
    final tarifaLabel = tieneCosto && tarifa.isNotEmpty
        ? '\$$tarifa${modoTarifa == 'POR_HORA' ? '/h' : modoTarifa == 'POR_PERSONA' ? '/p' : ''}'
        : 'Gratis';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003F60), Color(0xFF005F8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIGURACIÓN · $completitud% COMPLETA',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFA8C5DB), fontWeight: FontWeight.w700, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 2),
                    Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(
                      color: activa ? const Color(0xFF7AC890) : Colors.orange,
                      shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 5),
                    Text(activa ? 'ACTIVA' : 'INACTIVA',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: completitud / 100,
              backgroundColor: Colors.white.withValues(alpha:0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7AC890)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniKpi(icon: Icons.groups_outlined, label: 'Aforo', value: aforo > 0 ? '$aforo' : '—'),
              _MiniKpi(icon: Icons.schedule_outlined, label: 'Grupos', value: numGrupos > 0 ? '$numGrupos' : '—'),
              _MiniKpi(icon: Icons.payments_outlined, label: 'Tarifa', value: tarifaLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniKpi({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: const Color(0xFFA8C5DB)),
              const SizedBox(width: 4),
              Flexible(child: Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFFA8C5DB), letterSpacing: 0.4), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SectionCard — tarjeta colapsable con header de estado
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool expanded;
  final bool complete;
  final VoidCallback onTap;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.expanded,
    this.complete = false,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = expanded ? iconColor.withValues(alpha:0.55) : cs.outlineVariant.withValues(alpha:0.45);
    final bgColor = expanded ? iconColor.withValues(alpha:0.04) : cs.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: expanded ? 1.4 : 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Borde izquierdo coloreado
              Container(width: 4, color: iconColor.withValues(alpha:expanded ? 0.85 : 0.35)),

              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha:0.13),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, size: 18, color: iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    if (complete) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.okSoft,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('LISTO', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800,
                                            color: AppColors.ok, letterSpacing: 0.4)),
                                      ),
                                    ],
                                  ]),
                                  Text(subtitle,
                                      style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: expanded ? iconColor : cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    if (expanded)
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha:0.7),
                          border: Border(top: BorderSide(color: iconColor.withValues(alpha:0.18), width: 1)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: child,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Editor de horarios por grupos — Variante C del mockup
// ═══════════════════════════════════════════════════════════════════════════

class _EditorHorarioGrupos extends StatelessWidget {
  final List<HorarioGrupoModel> grupos;
  final void Function(List<HorarioGrupoModel>) onChanged;

  const _EditorHorarioGrupos({required this.grupos, required this.onChanged});

  static const _kDias = ['LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'];
  static const _kDiasCortos = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  static const _kColores = [AppColors.blue, AppColors.orange, AppColors.teal, AppColors.purple, AppColors.green];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info
        if (grupos.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.bgOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Crea grupos de días con el mismo horario. Ej: "Días de semana" con 08:00–18:00, "Viernes" con 08:00–23:00.',
                style: TextStyle(fontSize: 11.5, color: AppColors.orange, height: 1.4),
              )),
            ]),
          ),

        // Lista de grupos
        ...grupos.asMap().entries.map((entry) {
          final i = entry.key;
          final grupo = entry.value;
          final color = _kColores[i % _kColores.length];
          return _GrupoCard(
            grupo: grupo,
            color: color,
            diasConst: _kDias,
            diasCortos: _kDiasCortos,
            onUpdate: (g) {
              final updated = List<HorarioGrupoModel>.from(grupos);
              updated[i] = g;
              onChanged(updated);
            },
            onDelete: () {
              final updated = List<HorarioGrupoModel>.from(grupos)..removeAt(i);
              onChanged(updated);
            },
          );
        }),

        // Botón nuevo grupo
        InkWell(
          onTap: () => _abrirDialogNuevoGrupo(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha:0.5), style: BorderStyle.solid, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: AppColors.orange),
                const SizedBox(width: 6),
                Text('Nuevo grupo de días', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.orange)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _abrirDialogNuevoGrupo(BuildContext context) async {
    final result = await showDialog<HorarioGrupoModel>(
      context: context,
      builder: (ctx) => _GrupoDialog(diasOcupados: _diasOcupados()),
    );
    if (result != null) {
      onChanged([...grupos, result]);
    }
  }

  Set<String> _diasOcupados() {
    final ocupados = <String>{};
    for (final g in grupos) {
      ocupados.addAll(g.listaDias);
    }
    return ocupados;
  }
}

class _GrupoCard extends StatelessWidget {
  final HorarioGrupoModel grupo;
  final Color color;
  final List<String> diasConst;
  final List<String> diasCortos;
  final void Function(HorarioGrupoModel) onUpdate;
  final VoidCallback onDelete;

  const _GrupoCard({
    required this.grupo,
    required this.color,
    required this.diasConst,
    required this.diasCortos,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        // Borde izquierdo de color
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(child: Text(grupo.etiqueta,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 16, color: color),
                          onPressed: () => _editar(context),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                          onPressed: onDelete,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Pildoras de días
                    Row(
                      children: List.generate(diasConst.length, (i) {
                        final sel = grupo.listaDias.contains(diasConst[i]);
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 28, height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel ? color : Colors.transparent,
                              border: Border.all(color: sel ? color : Theme.of(context).dividerColor),
                            ),
                            child: Text(diasCortos[i],
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Franjas
                    ...grupo.franjas.map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.access_time, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text('${f.horaInicio} → ${f.horaFin}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                        const Spacer(),
                        Text(f.duracion, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ]),
                    )),
                    if (grupo.nota != null && grupo.nota!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.info_outline, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(child: Text(grupo.nota!,
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic))),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editar(BuildContext context) async {
    final result = await showDialog<HorarioGrupoModel>(
      context: context,
      builder: (ctx) => _GrupoDialog(grupo: grupo, diasOcupados: const {}),
    );
    if (result != null) onUpdate(result);
  }
}

// Dialog para crear/editar un grupo de horario
class _GrupoDialog extends StatefulWidget {
  final HorarioGrupoModel? grupo;
  final Set<String> diasOcupados;
  const _GrupoDialog({this.grupo, required this.diasOcupados});

  @override
  State<_GrupoDialog> createState() => _GrupoDialogState();
}

class _GrupoDialogState extends State<_GrupoDialog> {
  static const _kDias = ['LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'];
  static const _kDiasCortos = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  final _etiquetaCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  Set<String> _diasSel = {};
  List<_FranjaEditable> _franjas = [];

  @override
  void initState() {
    super.initState();
    final g = widget.grupo;
    if (g != null) {
      _etiquetaCtrl.text = g.etiqueta;
      _notaCtrl.text = g.nota ?? '';
      _diasSel = Set.from(g.listaDias);
      _franjas = g.franjas.map((f) => _FranjaEditable(inicio: f.horaInicio, fin: f.horaFin)).toList();
    }
    if (_franjas.isEmpty) _franjas.add(_FranjaEditable());
  }

  @override
  void dispose() {
    _etiquetaCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_etiquetaCtrl.text.trim().isEmpty) return;
    if (_diasSel.isEmpty) return;

    final franjas = _franjas
        .where((f) => f.inicio.isNotEmpty && f.fin.isNotEmpty)
        .map((f) => FranjaHorariaModel(horaInicio: f.inicio, horaFin: f.fin))
        .toList();

    final orden = _kDias.indexOf(_kDias.firstWhere(
      (d) => _diasSel.contains(d), orElse: () => _kDias[0]));

    Navigator.pop(context, HorarioGrupoModel(
      id: widget.grupo?.id,
      etiqueta: _etiquetaCtrl.text.trim(),
      dias: _kDias.where((d) => _diasSel.contains(d)).join(','),
      nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      orden: orden,
      franjas: franjas,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.grupo == null ? 'Nuevo grupo de horario' : 'Editar grupo'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('Nombre del grupo'),
              TextField(
                controller: _etiquetaCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej: Días de semana, Viernes, Fin de semana',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              _Label('Días del grupo'),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: List.generate(_kDias.length, (i) {
                  final dia = _kDias[i];
                  final sel = _diasSel.contains(dia);
                  final ocupado = widget.diasOcupados.contains(dia) && !sel;
                  return GestureDetector(
                    onTap: ocupado ? null : () {
                      setState(() {
                        if (sel) {
                          _diasSel.remove(dia);
                        } else {
                          _diasSel.add(dia);
                        }
                      });
                    },
                    child: Container(
                      width: 38, height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? AppColors.blue : ocupado ? Colors.grey.shade100 : Colors.transparent,
                        border: Border.all(
                          color: sel ? AppColors.blue : ocupado ? Colors.grey.shade300 : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(_kDiasCortos[i],
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : ocupado ? Colors.grey : Colors.black87,
                          )),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              _Label('Franjas horarias'),
              ..._franjas.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: _TimeField(
                    label: 'Inicio',
                    value: e.value.inicio,
                    onChanged: (v) => setState(() => _franjas[e.key].inicio = v),
                  )),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→')),
                  Expanded(child: _TimeField(
                    label: 'Fin',
                    value: e.value.fin,
                    onChanged: (v) => setState(() => _franjas[e.key].fin = v),
                  )),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                    onPressed: _franjas.length > 1
                        ? () => setState(() => _franjas.removeAt(e.key))
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ]),
              )),
              TextButton.icon(
                onPressed: () => setState(() => _franjas.add(_FranjaEditable())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Añadir franja'),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue),
              ),
              const SizedBox(height: 8),
              _Label('Nota interna', hint: 'Opcional'),
              TextField(
                controller: _notaCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej: Horario extendido los viernes de evento',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar grupo')),
      ],
    );
  }
}

class _FranjaEditable {
  String inicio;
  String fin;
  _FranjaEditable({this.inicio = '', this.fin = ''});
}

class _TimeField extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;
  const _TimeField({required this.label, required this.value, required this.onChanged});

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(
              widget.value.isEmpty ? '--:--' : widget.value,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: widget.value.isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : AppColors.blue,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    TimeOfDay initial = TimeOfDay.now();
    if (widget.value.isNotEmpty) {
      final parts = widget.value.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      widget.onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets utilitarios
// ═══════════════════════════════════════════════════════════════════════════

class _CategoriaSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  static const _cats = [
    ('SALON',    Icons.weekend_outlined,    'Salón'),
    ('PISCINA',  Icons.pool_outlined,       'Piscina'),
    ('GIMNASIO', Icons.fitness_center_outlined, 'Gimnasio'),
    ('BBQ',      Icons.outdoor_grill_outlined, 'BBQ'),
    ('CANCHA',   Icons.sports_soccer_outlined, 'Cancha'),
  ];

  const _CategoriaSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Categoría'),
        Row(
          children: _cats.map((cat) {
            final (key, icon, label) = cat;
            final sel = key == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(key),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.blue.withValues(alpha:0.10) : Colors.transparent,
                    border: Border.all(color: sel ? AppColors.blue : Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, size: 20, color: sel ? AppColors.blue : Colors.grey),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                          color: sel ? AppColors.blue : Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ModoUsoSelector extends StatelessWidget {
  final bool exclusivo;
  final void Function(bool) onChanged;
  const _ModoUsoSelector({required this.exclusivo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModoCard(
          icon: Icons.lock_outline,
          title: 'Uso exclusivo',
          subtitle: 'Una reserva a la vez bloquea toda la zona',
          color: AppColors.purple,
          selected: exclusivo,
          onTap: () => onChanged(true),
        ),
        const SizedBox(height: 8),
        _ModoCard(
          icon: Icons.groups_outlined,
          title: 'Uso compartido',
          subtitle: 'Pueden existir reservas simultáneas hasta completar el aforo',
          color: AppColors.teal,
          selected: !exclusivo,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ModoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ModoCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha:0.06) : Colors.transparent,
          border: Border.all(color: selected ? color : Theme.of(context).dividerColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: selected ? color : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: selected ? color : Theme.of(context).colorScheme.onSurface)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            )),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? color : Colors.grey, width: 2),
                color: selected ? color : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final Color color;
  final void Function(String) onChanged;

  const _SegmentedRow({
    required this.options, required this.labels, required this.selected,
    required this.color, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final sel = options[i] == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: sel ? [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 2)] : null,
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: sel ? color : cs.onSurfaceVariant)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final List<T> options;
  final List<String> labels;
  final T selected;
  final Color color;
  final void Function(T) onChanged;

  const _ChipSelector({
    required this.options, required this.labels, required this.selected,
    required this.color, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(options.length, (i) {
        final sel = options[i] == selected;
        return GestureDetector(
          onTap: () => onChanged(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? color : Colors.transparent,
              border: Border.all(color: sel ? color : Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(labels[i],
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        );
      }),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final void Function(bool) onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.color, required this.onChanged,
    this.isLast = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha:0.4))),
      ),
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: color),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? hint;
  const _Label(this.text, {this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Text('· $hint', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}
