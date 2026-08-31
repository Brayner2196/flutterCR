import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/currency_formatter.dart';

/// Lo que el residente eligió en el bottom sheet de "Pagar todo".
class PagoDeudaSeleccion {
  /// true → paga la deuda completa; el backend calcula el monto.
  final bool deudaCompleta;

  /// Monto ingresado a mano. Null cuando [deudaCompleta] es true.
  final double? monto;

  const PagoDeudaSeleccion.completa()
      : deudaCompleta = true,
        monto = null;

  const PagoDeudaSeleccion.parcial(this.monto) : deudaCompleta = false;
}

/// Pregunta cuánto quiere pagar de su deuda.
///
/// Dos caminos con destinos distintos a propósito: pagar todo va derecho a la pasarela
/// porque no hay nada que decidir, mientras que un valor parcial pasa antes por la
/// pantalla de distribución — ahí sí importa que el residente vea a cuáles cobros va a
/// parar su plata antes de ponerla.
Future<PagoDeudaSeleccion?> mostrarPagarDeudaSheet(
  BuildContext context, {
  required double totalDeuda,
  required double saldoFavor,
  required int cantidadCobros,
}) {
  return showModalBottomSheet<PagoDeudaSeleccion>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _PagarDeudaSheet(
        totalDeuda: totalDeuda,
        saldoFavor: saldoFavor,
        cantidadCobros: cantidadCobros,
      ),
    ),
  );
}

class _PagarDeudaSheet extends StatefulWidget {
  final double totalDeuda;
  final double saldoFavor;
  final int cantidadCobros;

  const _PagarDeudaSheet({
    required this.totalDeuda,
    required this.saldoFavor,
    required this.cantidadCobros,
  });

  @override
  State<_PagarDeudaSheet> createState() => _PagarDeudaSheetState();
}

class _PagarDeudaSheetState extends State<_PagarDeudaSheet> {
  /// El sheet arranca con las dos opciones y se transforma en el formulario del
  /// monto sin cerrarse: cerrar y volver a abrir pierde el contexto de lo que debe.
  bool _ingresandoMonto = false;

  final _montoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Lo que hay que poner de bolsillo: la deuda menos lo que ya tiene a favor.
  double get _neto {
    final neto = widget.totalDeuda - widget.saldoFavor;
    return neto > 0 ? neto : 0;
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _encabezado(),
            const SizedBox(height: 20),
            if (_ingresandoMonto) _formularioMonto() else _opciones(),
          ],
        ),
      ),
    );
  }

  // ─── Encabezado ───────────────────────────────────────────────────────────

  Widget _encabezado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _ingresandoMonto ? '¿Cuánto quieres abonar?' : 'Pagar tu deuda',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.cantidadCobros} cobros pendientes · '
          '${CurrencyFormatter.cop(widget.totalDeuda)}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        if (widget.saldoFavor > 0) ...[
          const SizedBox(height: 2),
          Text(
            'Se descontará tu saldo a favor de ${CurrencyFormatter.cop(widget.saldoFavor)}',
            style: const TextStyle(fontSize: 12, color: Colors.teal),
          ),
        ],
      ],
    );
  }

  // ─── Paso 1: elegir ───────────────────────────────────────────────────────

  Widget _opciones() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            onPressed: () => setState(() => _ingresandoMonto = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Pagar un valor diferente',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () =>
                Navigator.pop(context, const PagoDeudaSeleccion.completa()),
            child: Text(
              'Pagar todo (${CurrencyFormatter.cop(_neto)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Se aplica primero a los cobros más antiguos.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ─── Paso 2: monto a mano ─────────────────────────────────────────────────

  Widget _formularioMonto() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _montoCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Monto a pagar',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            validator: _validarMonto,
          ),
          const SizedBox(height: 8),
          Text(
            'Verás cómo se reparte antes de confirmar el pago.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _ingresandoMonto = false),
                child: const Text('Volver'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmarMonto,
                  child: const Text(
                    'Ver distribución',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validarMonto(String? valor) {
    final monto = double.tryParse((valor ?? '').trim());
    if (monto == null || monto <= 0) return 'Ingresa un monto válido';
    // El backend rechaza montos que redondean a cero en centavos; se avisa antes.
    if (monto < 1) return 'El monto mínimo es \$1';
    return null;
  }

  void _confirmarMonto() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final monto = double.parse(_montoCtrl.text.trim());
    Navigator.pop(context, PagoDeudaSeleccion.parcial(monto));
  }
}
