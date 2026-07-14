import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/configuracion_plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';

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

  late bool _activo;
  late bool _recargoActivo;
  late bool _moraCongelada;
  late bool _aprobacionAuto;
  bool _guardando = false;

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
      _maxCuotasCtrl.text = cfg.maxCuotas.toString();
      _recargoCtrl.text = cfg.porcentajeRecargo > 0
          ? cfg.porcentajeRecargo.toString()
          : '';
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final nuevo = ConfiguracionPlanPagoModel(
      activo: _activo,
      maxCuotas: int.parse(_maxCuotasCtrl.text.trim()),
      recargoFraccionamiento: _recargoActivo,
      porcentajeRecargo: _recargoActivo && _recargoCtrl.text.trim().isNotEmpty
          ? double.parse(_recargoCtrl.text.trim())
          : 0,
      moraCongeladaDurantePlan: _moraCongelada,
      aprobacionAutomatica: _aprobacionAuto,
    );

    try {
      await context.read<PlanPagoProvider>().guardarConfig(nuevo);
      if (!mounted) return;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlanPagoProvider>();

    if (p.loading && p.config.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan de pago')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar plan de pago')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Módulo activo ────────────────────────────────────
            _SwitchTile(
              titulo: 'Módulo habilitado',
              subtitulo: _activo
                  ? 'Los residentes pueden solicitar planes de pago'
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
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
