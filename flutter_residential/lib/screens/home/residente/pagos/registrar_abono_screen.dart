import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/simular_abono_model.dart';
import '../../../../providers/abono_provider.dart';
import '../../../../services/abono_service.dart';

class RegistrarAbonoScreen extends StatefulWidget {
  final int propiedadId;
  final String propiedadNombre;
  /// Si viene de un cobro parcial, pre-llena el monto con el saldo restante
  final double? montoSugerido;

  const RegistrarAbonoScreen({
    super.key,
    required this.propiedadId,
    required this.propiedadNombre,
    this.montoSugerido,
  });

  @override
  State<RegistrarAbonoScreen> createState() => _RegistrarAbonoScreenState();
}

class _RegistrarAbonoScreenState extends State<RegistrarAbonoScreen> {
  final _form = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _metodo = 'TRANSFERENCIA';
  bool _enviando = false;

  SimularAbonoModel? _simulacion;
  bool _simulando = false;

  static const _metodos = ['TRANSFERENCIA', 'EFECTIVO', 'CHEQUE', 'OTRO'];

  @override
  void initState() {
    super.initState();
    if (widget.montoSugerido != null && widget.montoSugerido! > 0) {
      _montoCtrl.text = widget.montoSugerido!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    _comprobanteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _simular() async {
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;
    setState(() { _simulando = true; _simulacion = null; });
    try {
      final sim = await AbonoService.simular(widget.propiedadId, monto);
      if (mounted) setState(() => _simulacion = sim);
    } catch (_) {
      if (mounted) setState(() => _simulacion = null);
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Abono')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _resumenPropiedad(),
            if (widget.montoSugerido != null && widget.montoSugerido! > 0) ...[
              const SizedBox(height: 12),
              _BannerSaldoPendiente(monto: widget.montoSugerido!),
            ],
            const SizedBox(height: 20),
            Text('Datos del abono',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto a abonar',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa un monto';
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Monto inválido';
                      return null;
                    },
                    onChanged: (_) {
                      if (_simulacion != null) setState(() => _simulacion = null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: _simulando ? null : _simular,
                    icon: _simulando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.preview, size: 18),
                    label: const Text('Ver distribución'),
                  ),
                ),
              ],
            ),
            if (_simulacion != null) ...[
              const SizedBox(height: 16),
              _SimulacionCard(sim: _simulacion!),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _metodo,
              decoration: const InputDecoration(
                  labelText: 'Método de pago', border: OutlineInputBorder()),
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
              label: const Text('Enviar abono'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenPropiedad() => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.home_outlined, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.propiedadNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      );

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await context.read<AbonoProvider>().registrar({
        'propiedadId': widget.propiedadId,
        'montoTotal': double.parse(_montoCtrl.text.replaceAll(',', '.')),
        'fechaPago': DateTime.now().toIso8601String().substring(0, 10),
        'metodoPago': _metodo,
        if (_referenciaCtrl.text.isNotEmpty) 'referencia': _referenciaCtrl.text,
        if (_comprobanteCtrl.text.isNotEmpty) 'urlComprobante': _comprobanteCtrl.text,
        if (_notasCtrl.text.isNotEmpty) 'notas': _notasCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Abono enviado, pendiente de verificación'),
          backgroundColor: Colors.green,
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
}

// ─── Banner saldo pendiente ──────────────────────────────────────

class _BannerSaldoPendiente extends StatelessWidget {
  final double monto;
  const _BannerSaldoPendiente({required this.monto});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'Saldo pendiente por pagar: '),
                  TextSpan(
                    text: _fmt(monto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preview de distribución ─────────────────────────────────────

class _SimulacionCard extends StatelessWidget {
  final SimularAbonoModel sim;
  const _SimulacionCard({required this.sim});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text('Distribución del abono',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.primary)),
          ]),
          if (sim.saldoFavorPrevio > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Saldo a favor previo: ${_fmt(sim.saldoFavorPrevio)}  →  Total disponible: ${_fmt(sim.totalDisponible)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          ...sim.distribucion.map((m) => _FilaMovimiento(m: m)),
          if (sim.saldoFavorResultante > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo a tu favor',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal)),
                Text(_fmt(sim.saldoFavorResultante),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _FilaMovimiento extends StatelessWidget {
  final dynamic m;
  const _FilaMovimiento({required this.m});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            m.esSaldoFavor ? Icons.savings_outlined : Icons.check_circle_outline,
            size: 16,
            color: m.esSaldoFavor ? Colors.teal : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(m.descripcion,
                  style: const TextStyle(fontSize: 13))),
          Text(
            '\$${m.montoAplicado.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
