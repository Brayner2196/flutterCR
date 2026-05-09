import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cobro_model.dart';
import '../../providers/pagos_provider.dart';

class RegistrarPagoScreen extends StatefulWidget {
  final CobroModel cobro;
  /// Si se especifica, pre-llena el monto (útil para cobros parciales).
  final double? montoPagar;
  /// Saldo a favor disponible — descuenta del monto inicial sugerido.
  final double saldoFavor;

  const RegistrarPagoScreen({
    super.key,
    required this.cobro,
    this.montoPagar,
    this.saldoFavor = 0.0,
  });

  @override
  State<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends State<RegistrarPagoScreen> {
  final _form = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _metodo = 'TRANSFERENCIA';
  bool _enviando = false;

  static const _metodos = ['TRANSFERENCIA', 'EFECTIVO', 'CHEQUE', 'OTRO'];

  double get _montoPendiente => widget.cobro.montoPendiente;
  /// Monto que el usuario realmente necesita transferir (pendiente - saldo a favor).
  double get _montoSugerido =>
      max(0.0, _montoPendiente - widget.saldoFavor);
  /// Saldo a favor que se consumirá al verificar (el mínimo entre SF y pendiente).
  double get _saldoAplicado =>
      min(widget.saldoFavor, _montoPendiente);
  double get _montoIngresado =>
      double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
  /// Exceso: lo que sobra respecto al pendiente total (va a saldo a favor).
  double get _exceso =>
      (_montoIngresado - _montoPendiente).clamp(0, double.infinity);
  bool get _hayExceso => _exceso > 0;

  @override
  void initState() {
    super.initState();
    // Pre-llenar con montoPagar explícito (si viene) o con el monto sugerido
    // descontando el saldo a favor disponible.
    final base = widget.montoPagar ?? widget.cobro.montoPendiente;
    final inicial = max(0.0, base - widget.saldoFavor);
    _montoCtrl.text = inicial.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    _comprobanteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Pago')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _resumenCobro(),
            const SizedBox(height: 20),
            Text('Datos del pago',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── Monto ──────────────────────────────────────────────
            TextFormField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa un monto';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Monto inválido';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            // ── Banner exceso → saldo a favor ──────────────────────
            if (_hayExceso) ...[
              const SizedBox(height: 8),
              _BannerExceso(exceso: _exceso, fmt: _fmt),
            ],

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _metodo,
              decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder()),
              items: _metodos
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _metodo = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenciaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Número de referencia / comprobante',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comprobanteCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL del comprobante (opcional)',
                  hintText: 'https://',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Enviar comprobante'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenCobro() => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen del cobro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.cobro.propiedadIdentificador),
                  Text(
                    _fmt(_montoPendiente),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              Text(
                '${widget.cobro.concepto} · ${widget.cobro.mes}/${widget.cobro.anio}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (widget.cobro.esParcial) ...[
                const SizedBox(height: 4),
                Text(
                  'Total original: ${_fmt(widget.cobro.montoTotal)} — ya abonado: ${_fmt(widget.cobro.montoPagado)}',
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ],
              if (widget.saldoFavor > 0) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings_outlined,
                            color: Colors.teal, size: 14),
                        const SizedBox(width: 4),
                        const Text('Saldo a favor',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal)),
                      ],
                    ),
                    Text(
                      '− ${_fmt(_saldoAplicado)}',
                      style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transferencia necesaria',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800)),
                    Text(
                      _fmt(_montoSugerido),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final monto =
          double.parse(_montoCtrl.text.replaceAll(',', '.'));
      await context.read<PagosProvider>().registrar({
        'cobroId': widget.cobro.id,
        'montoPagado': monto,
        'fechaPago': DateTime.now().toIso8601String().substring(0, 10),
        'metodoPago': _metodo,
        if (_referenciaCtrl.text.isNotEmpty)
          'referencia': _referenciaCtrl.text,
        if (_comprobanteCtrl.text.isNotEmpty)
          'urlComprobante': _comprobanteCtrl.text,
        if (_notasCtrl.text.isNotEmpty) 'notas': _notasCtrl.text,
      });
      if (mounted) {
        final msg = _hayExceso
            ? 'Pago enviado. El exceso de ${_fmt(_exceso)} quedará como saldo a favor una vez verificado.'
            : 'Pago enviado, pendiente de verificación';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

// ─── Banner exceso → saldo a favor ───────────────────────────────────────────

class _BannerExceso extends StatelessWidget {
  final double exceso;
  final String Function(double) fmt;
  const _BannerExceso({required this.exceso, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Colors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'El exceso de '),
                  TextSpan(
                    text: fmt(exceso),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const TextSpan(
                      text:
                          ' quedará como saldo a favor al verificarse el pago.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
