import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_residential/features/reservas/models/reserva_model.dart';
import 'package:flutter_residential/features/reservas/services/reserva_service.dart';

/// Formulario bottom-sheet para crear o editar una zona común.
class ZonaFormSheet extends StatefulWidget {
  final ZonaComunModel? zona;
  final VoidCallback onGuardado;

  const ZonaFormSheet({super.key, this.zona, required this.onGuardado});

  @override
  State<ZonaFormSheet> createState() => _ZonaFormSheetState();
}

class _ZonaFormSheetState extends State<ZonaFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final _durMinCtrl = TextEditingController();
  final _durMaxCtrl = TextEditingController();
  final _antMinCtrl = TextEditingController();
  final _antMaxCtrl = TextEditingController();

  // Estado
  TimeOfDay? _horaApertura;
  TimeOfDay? _horaCierre;
  final Set<String> _dias = {};
  bool _requiereAprobacion = true;
  bool _guardando = false;

  static const _diasSemana = [
    'LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'
  ];

  static const _diasLabel = {
    'LUNES': 'Lu',
    'MARTES': 'Ma',
    'MIERCOLES': 'Mi',
    'JUEVES': 'Ju',
    'VIERNES': 'Vi',
    'SABADO': 'Sa',
    'DOMINGO': 'Do',
  };

  bool get _esEdicion => widget.zona != null;

  @override
  void initState() {
    super.initState();
    final z = widget.zona;
    if (z != null) {
      _nombreCtrl.text = z.nombre;
      _descripcionCtrl.text = z.descripcion ?? '';
      _capacidadCtrl.text = z.capacidad > 0 ? z.capacidad.toString() : '';
      if (z.duracionMinMinutos != null) _durMinCtrl.text = z.duracionMinMinutos.toString();
      if (z.duracionMaxMinutos != null) _durMaxCtrl.text = z.duracionMaxMinutos.toString();
      if (z.anticipacionMinDias != null) _antMinCtrl.text = z.anticipacionMinDias.toString();
      if (z.anticipacionMaxDias != null) _antMaxCtrl.text = z.anticipacionMaxDias.toString();
      _requiereAprobacion = z.requiereAprobacion;
      _dias.addAll(z.listaDias);

      if (z.horaApertura != null) {
        final p = z.horaApertura!.split(':');
        if (p.length >= 2) {
          _horaApertura = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      }
      if (z.horaCierre != null) {
        final p = z.horaCierre!.split(':');
        if (p.length >= 2) {
          _horaCierre = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _capacidadCtrl.dispose();
    _durMinCtrl.dispose();
    _durMaxCtrl.dispose();
    _antMinCtrl.dispose();
    _antMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora(bool esApertura) async {
    final inicial = esApertura ? (_horaApertura ?? const TimeOfDay(hour: 8, minute: 0))
                               : (_horaCierre  ?? const TimeOfDay(hour: 22, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esApertura) {
          _horaApertura = picked;
        } else {
          _horaCierre = picked;
        }
      });
    }
  }

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final data = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      if (_descripcionCtrl.text.trim().isNotEmpty)
        'descripcion': _descripcionCtrl.text.trim(),
      'capacidad': int.tryParse(_capacidadCtrl.text.trim()) ?? 0,
      if (_horaApertura != null) 'horaApertura': _formatHora(_horaApertura!),
      if (_horaCierre != null)   'horaCierre':   _formatHora(_horaCierre!),
      if (_dias.isNotEmpty) 'diasDisponibles': _dias.join(','),
      if (_durMinCtrl.text.trim().isNotEmpty)
        'duracionMinMinutos': int.parse(_durMinCtrl.text.trim()),
      if (_durMaxCtrl.text.trim().isNotEmpty)
        'duracionMaxMinutos': int.parse(_durMaxCtrl.text.trim()),
      if (_antMinCtrl.text.trim().isNotEmpty)
        'anticipacionMinDias': int.parse(_antMinCtrl.text.trim()),
      if (_antMaxCtrl.text.trim().isNotEmpty)
        'anticipacionMaxDias': int.parse(_antMaxCtrl.text.trim()),
      'requiereAprobacion': _requiereAprobacion,
    };

    try {
      if (_esEdicion) {
        await ReservaService.actualizarZona(widget.zona!.id, data);
      } else {
        await ReservaService.crearZona(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onGuardado();
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Text(
                _esEdicion ? 'Editar zona' : 'Nueva zona común',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Nombre ──────────────────────────────────────
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco('Nombre de la zona', Icons.pool_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Descripción ──────────────────────────────────
              TextFormField(
                controller: _descripcionCtrl,
                decoration: _deco('Descripción (opcional)', Icons.notes_outlined),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // ── Capacidad ────────────────────────────────────
              TextFormField(
                controller: _capacidadCtrl,
                decoration: _deco('Capacidad máx. (personas)', Icons.group_outlined),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 20),

              // ── Horario ──────────────────────────────────────
              _SectionLabel('Horario de operación'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _HoraTile(
                    label: 'Apertura',
                    hora: _horaApertura,
                    onTap: () => _seleccionarHora(true),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _HoraTile(
                    label: 'Cierre',
                    hora: _horaCierre,
                    onTap: () => _seleccionarHora(false),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // ── Días disponibles ─────────────────────────────
              _SectionLabel('Días disponibles'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _diasSemana.map((d) {
                  final sel = _dias.contains(d);
                  return FilterChip(
                    label: Text(_diasLabel[d]!),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      if (sel) {
                        _dias.remove(d);
                      } else {
                        _dias.add(d);
                      }
                    }),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.onPrimaryContainer,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: sel ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Duración de reserva ──────────────────────────
              _SectionLabel('Duración de reserva (minutos)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _durMinCtrl,
                    decoration: _deco('Mín.', Icons.timer_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _durMaxCtrl,
                    decoration: _deco('Máx.', Icons.timer_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )),
                ],
              ),
              const SizedBox(height: 12),

              // ── Anticipación ─────────────────────────────────
              _SectionLabel('Anticipación (días)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _antMinCtrl,
                    decoration: _deco('Mín.', Icons.calendar_today_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _antMaxCtrl,
                    decoration: _deco('Máx.', Icons.calendar_today_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // ── Requiere aprobación ──────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Requiere aprobación',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    _requiereAprobacion
                        ? 'El admin debe aprobar cada reserva'
                        : 'Las reservas se aprueban automáticamente',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  value: _requiereAprobacion,
                  onChanged: (v) => setState(() => _requiereAprobacion = v),
                ),
              ),
              const SizedBox(height: 28),

              // ── Botón guardar ────────────────────────────────
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando
                    ? 'Guardando...'
                    : _esEdicion ? 'Guardar cambios' : 'Crear zona'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );
}

// ── Tile de hora ──────────────────────────────────────────────────────────────

class _HoraTile extends StatelessWidget {
  final String label;
  final TimeOfDay? hora;
  final VoidCallback onTap;

  const _HoraTile({required this.label, required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tieneHora = hora != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: tieneHora ? cs.primary : cs.outline),
          borderRadius: BorderRadius.circular(12),
          color: tieneHora ? cs.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_outlined,
                size: 18,
                color: tieneHora ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: tieneHora ? cs.primary : cs.onSurfaceVariant)),
                  Text(
                    tieneHora
                        ? '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: tieneHora ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Label de sección ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
          letterSpacing: 0.5,
        ));
  }
}
