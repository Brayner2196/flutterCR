import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../providers/plan_pago_provider.dart';
import '../../widgets/preview_acuerdo_pago.dart';
import '../../widgets/selector_cuotas_acuerdo.dart';
import 'residente_mi_plan_screen.dart';

/// Solicitud de acuerdo de pago.
///
/// El residente elige cuántas cuotas y ve el desglose exacto —cuánto paga hoy
/// y cuánto queda diferido— antes de comprometerse. Todos los montos los
/// calcula el backend: la pantalla no multiplica ni divide nada, porque el
/// número que se muestra aquí es el que después se le va a cobrar.
///
/// Los cobros que entran al acuerdo tampoco se eligen aquí: los define la
/// parametrización del conjunto.
class ResidenteSolicitarPlanScreen extends StatefulWidget {
  /// Propiedad del acuerdo. Null si el residente tiene una sola.
  final int? propiedadId;

  const ResidenteSolicitarPlanScreen({super.key, this.propiedadId});

  @override
  State<ResidenteSolicitarPlanScreen> createState() =>
      _ResidenteSolicitarPlanScreenState();
}

class _ResidenteSolicitarPlanScreenState
    extends State<ResidenteSolicitarPlanScreen> {
  final _obsCtrl = TextEditingController();
  int _cuotas = 1;
  bool _enviando = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Tocar un provider en initState revienta en web y escritorio: se difiere
    // al primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PlanPagoProvider>();
      await provider.cargarConfigResidente();
      final elegibilidad =
          await provider.cargarElegibilidad(propiedadId: widget.propiedadId);
      if (!mounted) return;
      if (elegibilidad.elegible) _simular();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _obsCtrl.dispose();
    super.dispose();
  }

  /// Simula con retardo: el residente pasa de 3 a 6 cuotas más rápido de lo que
  /// responde la red, y sin esperar se dispara una petición por cada toque.
  void _simularConDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _simular);
  }

  void _simular() {
    if (!mounted) return;
    context
        .read<PlanPagoProvider>()
        .simular(propiedadId: widget.propiedadId, numeroCuotas: _cuotas);
  }

  Future<void> _solicitar() async {
    setState(() => _enviando = true);
    try {
      final plan = await context.read<PlanPagoProvider>().solicitar(
            propiedadId: widget.propiedadId,
            numeroCuotas: _cuotas,
            observaciones: _obsCtrl.text.trim(),
          );
      if (!mounted) return;
      _toast(
        ToastificationType.success,
        plan.esActivo
            ? 'Acuerdo aprobado — ya puedes pagar el abono inicial'
            : 'Solicitud enviada — esperando aprobación',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResidenteMiPlanScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
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
    final provider = context.watch<PlanPagoProvider>();
    final elegibilidad = provider.elegibilidad;
    final simulacion = provider.simulacion;
    final maxCuotas =
        elegibilidad.maxCuotas > 0 ? elegibilidad.maxCuotas : provider.config.maxCuotas;

    return Scaffold(
      appBar: AppBar(title: const Text('Acuerdo de pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!elegibilidad.elegible && elegibilidad.motivos.isNotEmpty) ...[
            _MotivosCard(motivos:
                elegibilidad.motivos.map((m) => m.mensaje).toList()),
            const SizedBox(height: 16),
          ],

          // ── Cuotas ───────────────────────────────────────
          const _Etiqueta('¿En cuántas cuotas quieres diferir el saldo?'),
          const SizedBox(height: 10),
          SelectorCuotasAcuerdo(
            maxCuotas: maxCuotas,
            cuotas: _cuotas,
            habilitado: elegibilidad.elegible && !_enviando,
            onChanged: (v) {
              setState(() => _cuotas = v);
              _simularConDebounce();
            },
          ),
          const SizedBox(height: 20),

          // ── Previsualización ─────────────────────────────
          const _Etiqueta('Así quedaría tu acuerdo'),
          const SizedBox(height: 10),
          if (provider.simulando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.errorSimulacion != null)
            _AvisoCard(
              texto: provider.errorSimulacion!,
              color: AppColors.warning,
              fondo: AppColors.warningSoft,
              icono: Icons.error_outline,
            )
          else if (simulacion != null)
            PreviewAcuerdoPago.deSimulacion(simulacion)
          else
            const _AvisoCard(
              texto: 'Selecciona el número de cuotas para ver el detalle',
              color: AppColors.blue,
              fondo: AppColors.bgBlue,
              icono: Icons.info_outline,
            ),

          const SizedBox(height: 18),

          // ── Observaciones ────────────────────────────────
          TextField(
            controller: _obsCtrl,
            maxLines: 3,
            enabled: elegibilidad.elegible && !_enviando,
            decoration: InputDecoration(
              labelText: 'Observaciones (opcional)',
              hintText: 'Agrega una nota para el administrador...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          // ── Qué pasa después ─────────────────────────────
          if (simulacion != null)
            _AvisoCard(
              texto: simulacion.requiereAprobacion
                  ? 'Ahora no pagas nada. Tu solicitud la revisa el administrador; '
                      'cuando la apruebe se generan el pago inicial y las cuotas.'
                  : 'Al enviar, el acuerdo queda celebrado: se generan el pago '
                      'inicial y las cuotas, y tus cobros actuales se reemplazan.',
              color: AppColors.blue,
              fondo: AppColors.bgBlue,
              icono: Icons.info_outline,
            ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: (!elegibilidad.elegible ||
                    _enviando ||
                    simulacion == null ||
                    provider.simulando)
                ? null
                : _solicitar,
            icon: _enviando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.handshake_outlined),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            label: Text(_textoBoton(simulacion?.requiereAprobacion ?? true)),
          ),
        ],
      ),
    );
  }

  String _textoBoton(bool requiereAprobacion) {
    if (_enviando) return 'Enviando...';
    return requiereAprobacion ? 'Enviar solicitud' : 'Celebrar acuerdo';
  }
}

// ── Auxiliares ───────────────────────────────────────────────────────────────

class _Etiqueta extends StatelessWidget {
  final String text;
  const _Etiqueta(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: cs.primary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;
  final IconData icono;

  const _AvisoCard({
    required this.texto,
    required this.color,
    required this.fondo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}

class _MotivosCard extends StatelessWidget {
  final List<String> motivos;
  const _MotivosCard({required this.motivos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.block_outlined, size: 16, color: AppColors.warning),
              SizedBox(width: 6),
              Text(
                'Todavía no puedes solicitar un acuerdo',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...motivos.map((m) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.warning)),
                    Expanded(
                      child: Text(m,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warning)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
