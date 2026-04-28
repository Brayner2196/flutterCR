import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../models/reserva_model.dart';
import '../../../../providers/reserva_provider.dart';

class CrearReservaScreen extends StatefulWidget {
  const CrearReservaScreen({super.key});

  @override
  State<CrearReservaScreen> createState() => _CrearReservaScreenState();
}

class _CrearReservaScreenState extends State<CrearReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesCtrl = TextEditingController();

  ZonaComunModel? _zonaSeleccionada;
  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
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
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy.add(const Duration(days: 1)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 90)),
    );
    if (seleccion != null) setState(() => _fecha = seleccion);
  }

  Future<void> _seleccionarHora({required bool esInicio}) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: esInicio
          ? (_horaInicio ?? const TimeOfDay(hour: 8, minute: 0))
          : (_horaFin ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaFin = hora;
        }
      });
    }
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_zonaSeleccionada == null ||
        _fecha == null ||
        _horaInicio == null ||
        _horaFin == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Completa todos los campos obligatorios'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await context.read<ReservaProvider>().crearReserva({
        'zonaComunId': _zonaSeleccionada!.id,
        'fecha': _formatFecha(_fecha!),
        'horaInicio': _formatHora(_horaInicio!),
        'horaFin': _formatHora(_horaFin!),
        'observaciones': _observacionesCtrl.text.trim(),
      });
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Reserva creada exitosamente'),
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

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservaProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Zona común ──────────────────
              Text(
                'Zona Común',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ZonaComunModel>(
                value: _zonaSeleccionada,
                decoration: const InputDecoration(
                  hintText: 'Selecciona una zona',
                  border: OutlineInputBorder(),
                ),
                items: p.zonas
                    .map((z) => DropdownMenuItem(
                          value: z,
                          child: Text('${z.nombre} (Cap: ${z.capacidad})'),
                        ))
                    .toList(),
                onChanged: (z) => setState(() => _zonaSeleccionada = z),
                validator: (v) => v == null ? 'Selecciona una zona' : null,
              ),

              // ─── Descripción de zona ─────────
              if (_zonaSeleccionada?.descripcion != null &&
                  _zonaSeleccionada!.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _zonaSeleccionada!.descripcion!,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ─── Fecha ───────────────────────
              Text(
                'Fecha',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _fecha != null
                        ? _formatFecha(_fecha!)
                        : 'Selecciona una fecha',
                    style: TextStyle(
                      color: _fecha != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Horario ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora inicio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () =>
                              _seleccionarHora(esInicio: true),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.schedule),
                            ),
                            child: Text(
                              _horaInicio != null
                                  ? _formatHora(_horaInicio!)
                                  : '--:--',
                              style: TextStyle(
                                color: _horaInicio != null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora fin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () =>
                              _seleccionarHora(esInicio: false),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.schedule),
                            ),
                            child: Text(
                              _horaFin != null
                                  ? _formatHora(_horaFin!)
                                  : '--:--',
                              style: TextStyle(
                                color: _horaFin != null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Observaciones ────────────────
              Text(
                'Observaciones (opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Agrega alguna nota o detalle adicional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Botón enviar ─────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_enviando ? 'Enviando...' : 'Crear Reserva'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
