import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/cobro_model.dart';
import '../../../../providers/pagos_provider.dart';

class RegistrarPagoScreen extends StatefulWidget {
  final CobroModel cobro;
  const RegistrarPagoScreen({super.key, required this.cobro});

  @override
  State<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends State<RegistrarPagoScreen> {
  final _form = GlobalKey<FormState>();
  String _metodo = 'TRANSFERENCIA';
  final _referenciaCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _enviando = false;

  static const _metodos = [
    'TRANSFERENCIA', 'EFECTIVO', 'CHEQUE', 'OTRO'
  ];

  @override
  void dispose() {
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
            DropdownButtonFormField<String>(
              value: _metodo,
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
              label: const Text('Enviar comprobante'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenCobro() => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen del cobro',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.cobro.propiedadIdentificador),
                  Text(
                    _fmt(widget.cobro.montoTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              Text(
                  '${widget.cobro.concepto} · ${widget.cobro.mes}/${widget.cobro.anio}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await context.read<PagosProvider>().registrar({
        'cobroId': widget.cobro.id,
        'montoPagado': widget.cobro.montoTotal,
        'fechaPago': DateTime.now().toIso8601String().substring(0, 10),
        'metodoPago': _metodo,
        if (_referenciaCtrl.text.isNotEmpty)
          'referencia': _referenciaCtrl.text,
        if (_comprobanteCtrl.text.isNotEmpty)
          'urlComprobante': _comprobanteCtrl.text,
        if (_notasCtrl.text.isNotEmpty) 'notas': _notasCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pago enviado, pendiente de verificación'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
