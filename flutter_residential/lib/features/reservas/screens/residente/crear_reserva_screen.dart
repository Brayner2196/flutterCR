import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/reserva_model.dart';
import '../../providers/reserva_provider.dart';
import '../../services/reserva_service.dart';
import '../../utils/zona_disponibilidad_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Pantalla de nueva reserva — vista residente/inquilino
// Flujo progresivo: zona → fecha (solo días válidos) → franja → confirmar
// ═══════════════════════════════════════════════════════════════════════════

class CrearReservaScreen extends StatefulWidget {
  const CrearReservaScreen({super.key});

  @override
  State<CrearReservaScreen> createState() => _CrearReservaScreenState();
}

class _CrearReservaScreenState extends State<CrearReservaScreen> {
  final _obsCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  ZonaComunModel? _zona;
  DateTime? _fecha;
  FranjaHorariaModel? _franja;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaProvider>().cargarZonasActivas();
    });
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Selecciones ───────────────────────────────────────────────

  void _seleccionarZona(ZonaComunModel z) {
    setState(() { _zona = z; _fecha = null; _franja = null; });
    _scrollDown();
  }

  void _seleccionarFecha(DateTime d) {
    setState(() { _fecha = d; _franja = null; });
    _scrollDown();
  }

  void _seleccionarFranja(FranjaHorariaModel f) {
    setState(() => _franja = f);
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _listo => _zona != null && _fecha != null && _franja != null;

  Future<void> _enviar() async {
    if (!_listo) return;
    setState(() => _enviando = true);
    try {
      await context.read<ReservaProvider>().crearReserva({
        'zonaComunId': _zona!.id,
        'fecha': ZonaDisponibilidadHelper.formatFecha(_fecha!),
        'horaInicio': _franja!.horaInicio,
        'horaFin': _franja!.horaFin,
        'observaciones': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      });
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Reserva enviada exitosamente'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservaProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nueva Reserva'),
        centerTitle: false,
        elevation: 0,
      ),
      body: p.loading && p.zonas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : p.zonas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.place_outlined, size: 48, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('No hay zonas disponibles',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // 1 · Zona ──────────────────────────────────────
                    _SeccionHeader(
                      numero: '1',
                      titulo: '¿Qué espacio quieres reservar?',
                      completo: _zona != null,
                    ),
                    const SizedBox(height: 10),
                    ...p.zonas.map((z) => _ZonaCard(
                          zona: z,
                          seleccionada: _zona?.id == z.id,
                          onTap: () => _seleccionarZona(z),
                        )),

                    // 2 · Fecha ─────────────────────────────────────
                    if (_zona != null) ...[
                      const SizedBox(height: 20),
                      _SeccionHeader(
                        numero: '2',
                        titulo: 'Elige una fecha disponible',
                        subtitulo: _resumenDiasZona(_zona!),
                        completo: _fecha != null,
                      ),
                      const SizedBox(height: 10),
                      _SelectorFechas(
                        zona: _zona!,
                        fechaSeleccionada: _fecha,
                        onFecha: _seleccionarFecha,
                      ),
                    ],

                    // 3 · Franja ────────────────────────────────────
                    if (_fecha != null) ...[
                      const SizedBox(height: 20),
                      _SeccionHeader(
                        numero: '3',
                        titulo: 'Selecciona el horario',
                        completo: _franja != null,
                      ),
                      const SizedBox(height: 10),
                      _SelectorFranjas(
                        zona: _zona!,
                        fecha: _fecha!,
                        franjaSeleccionada: _franja,
                        onFranja: _seleccionarFranja,
                      ),
                    ],

                    // 4 · Resumen + observaciones ───────────────────
                    if (_franja != null) ...[
                      const SizedBox(height: 20),
                      _SeccionHeader(
                        numero: '4',
                        titulo: 'Detalles finales',
                        completo: false,
                      ),
                      const SizedBox(height: 10),
                      _ResumenCard(zona: _zona!, fecha: _fecha!, franja: _franja!),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _obsCtrl,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Nota o detalle adicional (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),

      bottomNavigationBar: _listo
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _BotonEnviar(
                  zona: _zona!,
                  enviando: _enviando,
                  onEnviar: _enviar,
                ),
              ),
            )
          : null,
    );
  }

  String _resumenDiasZona(ZonaComunModel zona) {
    final wds = ZonaDisponibilidadHelper.weekdaysDisponibles(zona);
    const nombres = {1:'Lun',2:'Mar',3:'Mié',4:'Jue',5:'Vie',6:'Sáb',7:'Dom'};
    final lista = [1,2,3,4,5,6,7]
        .where(wds.contains)
        .map((w) => nombres[w]!)
        .join(', ');
    return 'Disponible: $lista';
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _SeccionHeader extends StatelessWidget {
  final String numero;
  final String titulo;
  final String? subtitulo;
  final bool completo;

  const _SeccionHeader({
    required this.numero,
    required this.titulo,
    this.subtitulo,
    required this.completo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: completo ? AppColors.ok : cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completo
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(numero,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              if (subtitulo != null)
                Text(subtitulo!,
                    style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _ZonaCard extends StatelessWidget {
  final ZonaComunModel zona;
  final bool seleccionada;
  final VoidCallback onTap;

  const _ZonaCard({required this.zona, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = ZonaDisponibilidadHelper.colorCategoria(zona.categoria);
    final icon = ZonaDisponibilidadHelper.iconoCategoria(zona.categoria);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: seleccionada ? color.withOpacity(0.07) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada ? color : cs.outlineVariant.withOpacity(0.5),
            width: seleccionada ? 2 : 1,
          ),
          boxShadow: seleccionada
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(zona.nombre,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (seleccionada)
                          Icon(Icons.check_circle_rounded, color: color, size: 18),
                      ],
                    ),
                    if (zona.descripcion != null && zona.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(zona.descripcion!,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(icon: Icons.people_outline,
                            label: '${zona.capacidad} personas',
                            color: cs.onSurfaceVariant),
                        _Pill(icon: Icons.payments_outlined,
                            label: ZonaDisponibilidadHelper.textoCosto(zona),
                            color: zona.tieneCosto ? AppColors.warning : AppColors.ok),
                        if (zona.requiereAprobacion)
                          _Pill(icon: Icons.pending_actions_outlined,
                              label: 'Requiere aprobación',
                              color: AppColors.blue),
                      ],
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

class _SelectorFechas extends StatelessWidget {
  final ZonaComunModel zona;
  final DateTime? fechaSeleccionada;
  final ValueChanged<DateTime> onFecha;

  const _SelectorFechas({required this.zona, required this.fechaSeleccionada, required this.onFecha});

  @override
  Widget build(BuildContext context) {
    final fechas = ZonaDisponibilidadHelper.proximasFechas(zona);

    if (fechas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('No hay fechas disponibles próximamente',
                  style: TextStyle(color: AppColors.warning, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fechas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = fechas[i];
          final sel = fechaSeleccionada != null &&
              fechaSeleccionada!.year == d.year &&
              fechaSeleccionada!.month == d.month &&
              fechaSeleccionada!.day == d.day;
          final esNuevoMes = i == 0 || fechas[i - 1].month != d.month;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (esNuevoMes && i != 0)
                Container(
                    width: 1, height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.grey.withOpacity(0.3)),
              _FechaChip(
                fecha: d, seleccionada: sel, esNuevoMes: esNuevoMes,
                onTap: () => onFecha(d),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FechaChip extends StatelessWidget {
  final DateTime fecha;
  final bool seleccionada;
  final bool esNuevoMes;
  final VoidCallback onTap;

  const _FechaChip({required this.fecha, required this.seleccionada,
      required this.esNuevoMes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 58, height: 80,
        decoration: BoxDecoration(
          color: seleccionada ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? cs.primary : cs.outlineVariant.withOpacity(0.5),
            width: seleccionada ? 2 : 1,
          ),
          boxShadow: seleccionada
              ? [BoxShadow(color: cs.primary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0,2))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (esNuevoMes)
              Text(ZonaDisponibilidadHelper.nombreMesCorto(fecha).toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      color: seleccionada ? Colors.white.withOpacity(0.8) : cs.onSurfaceVariant,
                      letterSpacing: 0.5))
            else
              const SizedBox(height: 11),
            Text('${fecha.day}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                    color: seleccionada ? Colors.white : cs.onSurface, height: 1.1)),
            Text(ZonaDisponibilidadHelper.nombreDiaCorto(fecha).toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: seleccionada ? Colors.white.withOpacity(0.85) : cs.onSurfaceVariant,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Selector de franjas — StatefulWidget que consulta disponibilidad real por fecha

class _SelectorFranjas extends StatefulWidget {
  final ZonaComunModel zona;
  final DateTime fecha;
  final FranjaHorariaModel? franjaSeleccionada;
  final ValueChanged<FranjaHorariaModel> onFranja;

  const _SelectorFranjas({
    required this.zona,
    required this.fecha,
    required this.franjaSeleccionada,
    required this.onFranja,
  });

  @override
  State<_SelectorFranjas> createState() => _SelectorFranjasState();
}

class _SelectorFranjasState extends State<_SelectorFranjas> {
  DisponibilidadZonaModel? _disponibilidad;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(_SelectorFranjas old) {
    super.didUpdateWidget(old);
    // Recarga si cambió la zona o la fecha
    if (old.zona.id != widget.zona.id ||
        old.fecha.year != widget.fecha.year ||
        old.fecha.month != widget.fecha.month ||
        old.fecha.day != widget.fecha.day) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final fecha = ZonaDisponibilidadHelper.formatFecha(widget.fecha);
      final disp = await ReservaService.disponibilidadZona(widget.zona.id, fecha);
      if (mounted) setState(() { _disponibilidad = disp; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null || _disponibilidad == null || _disponibilidad!.franjas.isEmpty) {
      return _aviso('No hay franjas configuradas para este día');
    }
    return _buildContenido(context);
  }

  Widget _buildContenido(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disp = _disponibilidad!;
    final franjas = disp.franjas;

    // Separar en MAÑANA (< 12:00) y TARDE (>= 12:00)
    final manana = franjas.where((f) => f.esManana).toList();
    final tarde  = franjas.where((f) => !f.esManana).toList();
    final buffer = disp.bufferLimpiezaMinutos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nota del grupo
        if (disp.grupoNota != null && disp.grupoNota!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(disp.grupoNota!,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
            ]),
          ),

        if (manana.isNotEmpty) ...[
          _PeriodoHeader(icono: Icons.wb_sunny_outlined, label: 'Mañana', color: const Color(0xFFE67E22)),
          const SizedBox(height: 8),
          ...manana.map((f) => _FranjaTile(
                franja: f,
                buffer: buffer,
                seleccionada: widget.franjaSeleccionada?.horaInicio == f.horaInicio &&
                    widget.franjaSeleccionada?.horaFin == f.horaFin,
                onTap: f.libre ? () => widget.onFranja(FranjaHorariaModel(
                    horaInicio: f.horaInicio, horaFin: f.horaFin)) : null,
              )),
          if (tarde.isNotEmpty) const SizedBox(height: 16),
        ],

        if (tarde.isNotEmpty) ...[
          _PeriodoHeader(icono: Icons.nightlight_round_outlined, label: 'Tarde / Noche',
              color: const Color(0xFF5D6B8A)),
          const SizedBox(height: 8),
          ...tarde.map((f) => _FranjaTile(
                franja: f,
                buffer: buffer,
                seleccionada: widget.franjaSeleccionada?.horaInicio == f.horaInicio &&
                    widget.franjaSeleccionada?.horaFin == f.horaFin,
                onTap: f.libre ? () => widget.onFranja(FranjaHorariaModel(
                    horaInicio: f.horaInicio, horaFin: f.horaFin)) : null,
              )),
        ],
      ],
    );
  }

  Widget _aviso(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12)),
    child: Text(msg, style: TextStyle(color: AppColors.warning, fontSize: 13)),
  );
}

// ── Encabezado de periodo (MAÑANA / TARDE) ───────────────────────────────────

class _PeriodoHeader extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  const _PeriodoHeader({required this.icono, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icono, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.8)),
    ]);
  }
}

// ── Tarjeta de franja horaria ─────────────────────────────────────────────────

class _FranjaTile extends StatelessWidget {
  final FranjaDisponibilidadModel franja;
  final int buffer;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _FranjaTile({
    required this.franja,
    required this.buffer,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final libre = franja.libre;
    final durMin = franja.minutosFin - franja.minutosInicio;
    final durStr = _fmtDur(durMin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: seleccionada
                  ? cs.primary
                  : libre
                      ? cs.surface
                      : cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seleccionada
                    ? cs.primary
                    : libre
                        ? cs.outlineVariant.withOpacity(0.6)
                        : cs.outlineVariant.withOpacity(0.3),
                width: seleccionada ? 2 : 1,
              ),
              boxShadow: seleccionada
                  ? [BoxShadow(color: cs.primary.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Row(children: [
              // Ícono estado
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: seleccionada
                      ? Colors.white.withOpacity(0.15)
                      : libre
                          ? AppColors.ok.withOpacity(0.1)
                          : cs.outlineVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  seleccionada ? Icons.check_rounded
                      : libre ? Icons.schedule_rounded
                          : Icons.block_rounded,
                  size: 17,
                  color: seleccionada
                      ? Colors.white
                      : libre ? AppColors.ok : cs.outline,
                ),
              ),
              const SizedBox(width: 12),

              // Hora y duración
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${franja.horaInicio}  –  ${franja.horaFin}',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: seleccionada ? Colors.white
                            : libre ? cs.onSurface
                                : cs.onSurface.withOpacity(0.4),
                      )),
                  const SizedBox(height: 2),
                  Text(
                    seleccionada ? 'Seleccionada'
                        : libre ? 'libre · toca para elegir'
                            : 'Sin cupo disponible',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: seleccionada ? Colors.white.withOpacity(0.8)
                          : libre ? AppColors.ok
                              : cs.outline,
                    ),
                  ),
                ],
              )),

              // Badge duración / ocupación
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (durStr.isNotEmpty)
                  Text(durStr,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: seleccionada ? Colors.white.withOpacity(0.75) : cs.onSurfaceVariant,
                      )),
                if (!libre && franja.ocupados > 0)
                  Text('${franja.ocupados}/${franja.capacidad}',
                      style: TextStyle(fontSize: 10, color: AppColors.danger)),
              ]),
            ]),
          ),
        ),

        // Rangos ocupados (si hay y la franja no es completamente libre)
        if (!libre && franja.rangosOcupados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 4),
            child: Wrap(
              spacing: 6, runSpacing: 4,
              children: franja.rangosOcupados.map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                ),
                child: Text('${r.horaInicio}–${r.horaFin}',
                    style: TextStyle(fontSize: 10, color: AppColors.danger,
                        fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),

        // Buffer de limpieza
        if (buffer > 0)
          Padding(
            padding: const EdgeInsets.only(left: 50, bottom: 8),
            child: Row(children: [
              Container(width: 18, height: 1, color: AppColors.warning.withOpacity(0.4)),
              const SizedBox(width: 6),
              Icon(Icons.cleaning_services_outlined, size: 11, color: AppColors.warning.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text('Limpieza · ${buffer}min',
                  style: TextStyle(fontSize: 10, color: AppColors.warning.withOpacity(0.8))),
              Expanded(child: Container(
                  margin: const EdgeInsets.only(left: 6), height: 1,
                  color: AppColors.warning.withOpacity(0.4))),
            ]),
          ),
      ],
    );
  }

  String _fmtDur(int min) {
    if (min <= 0) return '';
    final h = min ~/ 60;
    final m = min % 60;
    if (m == 0) return '${h}h';
    if (h == 0) return '${m}min';
    return '${h}h ${m}min';
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _ResumenCard extends StatelessWidget {
  final ZonaComunModel zona;
  final DateTime fecha;
  final FranjaHorariaModel franja;

  const _ResumenCard({required this.zona, required this.fecha, required this.franja});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = ZonaDisponibilidadHelper.colorCategoria(zona.categoria);
    final icon  = ZonaDisponibilidadHelper.iconoCategoria(zona.categoria);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(zona.nombre,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color))),
            if (zona.requiereAprobacion)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.bgBlue, borderRadius: BorderRadius.circular(6)),
                child: Text('Requiere aprobación',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue)),
              ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(children: [
            _ResumenItem(icon: Icons.calendar_today_rounded, label: 'Fecha',
                valor: '${ZonaDisponibilidadHelper.nombreDiaCorto(fecha)} '
                    '${fecha.day} ${ZonaDisponibilidadHelper.nombreMes(fecha)} ${fecha.year}'),
            const SizedBox(width: 16),
            _ResumenItem(icon: Icons.schedule_rounded, label: 'Horario',
                valor: '${franja.horaInicio} – ${franja.horaFin}'),
          ]),
          if (zona.tieneCosto && zona.tarifaMonto != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              _ResumenItem(icon: Icons.payments_outlined, label: 'Costo estimado',
                  valor: ZonaDisponibilidadHelper.textoCosto(zona),
                  color: AppColors.warning),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color? color;

  const _ResumenItem({required this.icon, required this.label, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: c.withOpacity(0.7)),
          const SizedBox(width: 6),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
            ],
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _BotonEnviar extends StatelessWidget {
  final ZonaComunModel zona;
  final bool enviando;
  final VoidCallback onEnviar;

  const _BotonEnviar({required this.zona, required this.enviando, required this.onEnviar});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (zona.requiereAprobacion)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.blue),
                const SizedBox(width: 5),
                Text('Tu solicitud quedará en revisión del administrador',
                    style: TextStyle(fontSize: 11.5, color: AppColors.blue)),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity, height: 50,
          child: FilledButton.icon(
            onPressed: enviando ? null : onEnviar,
            icon: enviando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              enviando ? 'Enviando...'
                  : zona.requiereAprobacion ? 'Enviar solicitud' : 'Confirmar reserva',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
