import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../features/pagos/models/cobro_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/configuracion_plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';
import 'residente_mi_plan_screen.dart';

/// Pantalla que permite al residente seleccionar cobros vencidos/pendientes
/// y elegir el número de cuotas para solicitar un plan de pago.
class ResidenteSolicitarPlanScreen extends StatefulWidget {
  /// Cobros disponibles para incluir en el plan (pendientes/vencidos del estado de cuenta).
  final List<CobroModel> cobrosDisponibles;

  const ResidenteSolicitarPlanScreen({
    super.key,
    required this.cobrosDisponibles,
  });

  @override
  State<ResidenteSolicitarPlanScreen> createState() =>
      _ResidenteSolicitarPlanScreenState();
}

class _ResidenteSolicitarPlanScreenState
    extends State<ResidenteSolicitarPlanScreen> {
  final _obsCtrl = TextEditingController();
  final Set<int> _seleccionados = {};
  int _cuotas = 1;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Seleccionar todos por defecto
    _seleccionados.addAll(widget.cobrosDisponibles.map((c) => c.id));
    // Cargar configuración
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanPagoProvider>().cargarConfigResidente();
    });
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _montoSeleccionado => widget.cobrosDisponibles
      .where((c) => _seleccionados.contains(c.id))
      .fold(0, (s, c) => s + c.montoPendiente);

  double _calcularRecargo(ConfiguracionPlanPagoModel cfg) {
    if (!cfg.recargoFraccionamiento || cfg.porcentajeRecargo <= 0) return 0;
    return _montoSeleccionado * cfg.porcentajeRecargo / 100;
  }

  Future<void> _solicitar() async {
    if (_seleccionados.isEmpty) {
      _toast(ToastificationType.warning,
          'Selecciona al menos un cobro para incluir en el plan');
      return;
    }

    setState(() => _enviando = true);
    try {
      final plan = await context.read<PlanPagoProvider>().solicitar(
            cobrosIds: _seleccionados.toList(),
            numeroCuotas: _cuotas,
            observaciones: _obsCtrl.text.trim(),
          );
      if (!mounted) return;
      _toast(
        ToastificationType.success,
        plan.esActivo
            ? 'Plan aprobado automáticamente — cuotas generadas'
            : 'Solicitud enviada — esperando aprobación',
      );
      // Navegar a mi plan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResidenteMiPlanScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(
          ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _toast(ToastificationType tipo, String msg) {
    toastification.show(
      context: context,
      type: tipo,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<PlanPagoProvider>().config;
    final recargo = _calcularRecargo(cfg);
    final total = _montoSeleccionado + recargo;
    final montoCuota = _cuotas > 0 ? total / _cuotas : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar plan de pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Indicadores de reglas ─────────────────────────
          if (cfg.activo) ...[
            _ReglasCard(cfg: cfg),
            const SizedBox(height: 16),
          ],

          // ── Cobros disponibles ────────────────────────────
          _SectionLabel('Cobros a incluir en el plan'),
          const SizedBox(height: 8),
          if (widget.cobrosDisponibles.isEmpty)
            _EmptyInfo('No tienes cobros pendientes para fraccionar')
          else
            ...widget.cobrosDisponibles.map((cobro) {
              final sel = _seleccionados.contains(cobro.id);
              return _CobroCheckTile(
                cobro: cobro,
                seleccionado: sel,
                onToggle: (v) {
                  setState(() {
                    if (v) {
                      _seleccionados.add(cobro.id);
                    } else {
                      _seleccionados.remove(cobro.id);
                    }
                  });
                },
              );
            }),
          const SizedBox(height: 20),

          // ── Número de cuotas ──────────────────────────────
          _SectionLabel('Número de cuotas'),
          const SizedBox(height: 10),
          _CuotaSelector(
            maxCuotas: cfg.maxCuotas,
            cuotas: _cuotas,
            onChanged: (v) => setState(() => _cuotas = v),
          ),
          const SizedBox(height: 20),

          // ── Resumen ───────────────────────────────────────
          _ResumenCard(
            montoDeuda: _montoSeleccionado,
            recargo: recargo,
            total: total,
            cuotas: _cuotas,
            montoCuota: montoCuota.toDouble(),
            recargoActivo: cfg.recargoFraccionamiento,
            porcentajeRecargo: cfg.porcentajeRecargo,
          ),
          const SizedBox(height: 16),

          // ── Observaciones ─────────────────────────────────
          TextField(
            controller: _obsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observaciones (opcional)',
              hintText: 'Agrega una nota para el administrador...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // ── Aviso aprobación ──────────────────────────────
          if (!cfg.aprobacionAutomatica)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu solicitud será revisada por el administrador antes de activarse.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),

          // ── Botón enviar ──────────────────────────────────
          FilledButton.icon(
            onPressed: (_enviando || _seleccionados.isEmpty) ? null : _solicitar,
            icon: _enviando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            label: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
          ),
        ],
      ),
    );
  }
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

class _EmptyInfo extends StatelessWidget {
  final String text;
  const _EmptyInfo(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
    );
  }
}

class _ReglasCard extends StatelessWidget {
  final ConfiguracionPlanPagoModel cfg;
  const _ReglasCard({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.blue),
            const SizedBox(width: 6),
            Text('Condiciones del plan',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue)),
          ]),
          const SizedBox(height: 6),
          _Regla('Máximo ${cfg.maxCuotas} cuotas'),
          if (cfg.recargoFraccionamiento)
            _Regla('Recargo del ${cfg.porcentajeRecargo.toStringAsFixed(1)}% sobre la deuda'),
          _Regla(cfg.moraCongeladaDurantePlan
              ? 'La mora se congela mientras el plan esté activo'
              : 'La mora continúa acumulando durante el plan'),
          _Regla(cfg.aprobacionAutomatica
              ? 'Aprobación automática'
              : 'Requiere aprobación del administrador'),
        ],
      ),
    );
  }
}

class _Regla extends StatelessWidget {
  final String text;
  const _Regla(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(fontSize: 12, color: AppColors.blue)),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: AppColors.blue)),
            ),
          ],
        ),
      );
}

class _CobroCheckTile extends StatelessWidget {
  final CobroModel cobro;
  final bool seleccionado;
  final ValueChanged<bool> onToggle;

  const _CobroCheckTile(
      {required this.cobro,
      required this.seleccionado,
      required this.onToggle});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seleccionado ? cs.primary : cs.outline,
          width: seleccionado ? 1.5 : 1,
        ),
        color: seleccionado
            ? cs.primary.withValues(alpha: 0.05)
            : cs.surface,
      ),
      child: CheckboxListTile(
        value: seleccionado,
        onChanged: (v) => onToggle(v ?? false),
        title: Text(
          cobro.descripcion ??
              '${cobro.concepto} — ${cobro.propiedadIdentificador}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Pendiente: ${_fmt(cobro.montoPendiente)}  ·  Vence: ${cobro.fechaLimitePago}',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        secondary: Text(
          _fmt(cobro.montoPendiente),
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: seleccionado ? cs.primary : cs.onSurface),
        ),
        activeColor: cs.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _CuotaSelector extends StatelessWidget {
  final int maxCuotas;
  final int cuotas;
  final ValueChanged<int> onChanged;

  const _CuotaSelector(
      {required this.maxCuotas,
      required this.cuotas,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(maxCuotas, (i) {
        final n = i + 1;
        final activo = cuotas == n;
        return GestureDetector(
          onTap: () => onChanged(n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: activo ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: activo ? cs.primary : cs.outline,
                  width: activo ? 1.5 : 1),
            ),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: activo ? Colors.white : cs.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final double montoDeuda;
  final double recargo;
  final double total;
  final int cuotas;
  final double montoCuota;
  final bool recargoActivo;
  final double porcentajeRecargo;

  const _ResumenCard({
    required this.montoDeuda,
    required this.recargo,
    required this.total,
    required this.cuotas,
    required this.montoCuota,
    required this.recargoActivo,
    required this.porcentajeRecargo,
  });

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _Row('Deuda seleccionada', _fmt(montoDeuda)),
          if (recargoActivo && recargo > 0)
            _Row('Recargo (${porcentajeRecargo.toStringAsFixed(1)}%)',
                _fmt(recargo),
                color: AppColors.warning),
          const Divider(height: 16),
          _Row('Total del plan', _fmt(total), bold: true),
          const SizedBox(height: 4),
          _Row('$cuotas cuota${cuotas != 1 ? 's' : ''} de',
              '≈ ${_fmt(montoCuota)}',
              color: cs.primary),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;
  final bool bold;

  const _Row(this.label, this.valor, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          Text(valor,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? cs.onSurface,
              )),
        ],
      ),
    );
  }
}
