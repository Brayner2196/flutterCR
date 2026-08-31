import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../models/simular_abono_model.dart';
import '../../services/abono_service.dart';
import '../../services/flujo_pago_service.dart';
import '../../widgets/distribucion_fifo_view.dart';

/// Última parada antes de la pasarela cuando el residente eligió un monto propio.
///
/// El backend reparte por FIFO: la plata baja por los cobros del más viejo al más nuevo,
/// sin importar cuál tenía en mente el residente. Esta pantalla convierte esa regla en
/// algo que se ve — qué cobros quedan saldados, cuál parcial, cuánto sobra — usando la
/// misma simulación que después ejecuta el reparto real, para que lo que se muestra y lo
/// que pasa no puedan divergir.
class DistribucionPagoScreen extends StatefulWidget {
  final int propiedadId;
  final double monto;

  const DistribucionPagoScreen({
    super.key,
    required this.propiedadId,
    required this.monto,
  });

  @override
  State<DistribucionPagoScreen> createState() => _DistribucionPagoScreenState();
}

class _DistribucionPagoScreenState extends State<DistribucionPagoScreen> {
  SimularAbonoModel? _simulacion;
  String? _error;
  bool _cargando = true;
  bool _pagando = false;

  @override
  void initState() {
    super.initState();
    _simular();
  }

  Future<void> _simular() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sim = await AbonoService.simular(widget.propiedadId, widget.monto);
      if (!mounted) return;
      setState(() {
        _simulacion = sim;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _pagar() async {
    setState(() => _pagando = true);
    try {
      final resultado = await FlujoPagoService.pagarDeuda(
        context: context,
        propiedadId: widget.propiedadId,
        titulo: 'Abono a tu deuda',
        monto: widget.monto,
      );
      if (!mounted) return;
      // El resultado sube a la pantalla de estado de cuenta, que es la que sabe
      // cómo refrescar los cobros y el saldo a favor.
      if (resultado != null) Navigator.of(context).pop(resultado);
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Así se aplicará tu pago')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _vistaError()
              : _vistaDistribucion(),
      bottomNavigationBar: (_cargando || _error != null) ? null : _barraPago(),
    );
  }

  Widget _vistaDistribucion() {
    final sim = _simulacion!;
    final cobrosCubiertos =
        sim.distribucion.where((m) => !m.esSaldoFavor).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _resumen(cobrosCubiertos),
        const SizedBox(height: 16),
        DistribucionFifoView(
          simulacion: sim,
          titulo: 'Detalle del reparto',
        ),
        const SizedBox(height: 16),
        _nota(),
      ],
    );
  }

  Widget _resumen(int cobrosCubiertos) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vas a pagar',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.cop(widget.monto),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            cobrosCubiertos == 0
                ? 'No alcanza a cubrir ningún cobro; quedará como saldo a favor.'
                : 'Cubre $cobrosCubiertos cobro${cobrosCubiertos == 1 ? '' : 's'}, '
                    'empezando por el más antiguo.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _nota() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'El reparto se confirma cuando la pasarela apruebe el pago. '
            'Si el monto cambia en la pasarela, se aplicará lo que realmente se cobró.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _simular,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraPago() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _pagando ? null : _pagar,
            child: _pagando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirmar y pagar ${CurrencyFormatter.cop(widget.monto)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
