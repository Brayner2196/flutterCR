import 'package:flutter/material.dart';
import '../../../../models/cobro_model.dart';
import 'registrar_pago_screen.dart';

class DetalleCobroScreen extends StatelessWidget {
  final CobroModel cobro;
  const DetalleCobroScreen({super.key, required this.cobro});

  @override
  Widget build(BuildContext context) {
    final color = cobro.esVencido
        ? Colors.red
        : cobro.esPagado
            ? Colors.green
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Cobro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _estadoBadge(color),
          const SizedBox(height: 16),
          _seccion('Información del cobro', [
            _fila('Propiedad', cobro.propiedadIdentificador),
            _fila('Período', '${cobro.mes}/${cobro.anio}'),
            _fila('Concepto', cobro.concepto),
            if (cobro.descripcion != null)
              _fila('Descripción', cobro.descripcion!),
            _fila('Generado', cobro.fechaGeneracion),
            _fila('Límite de pago', cobro.fechaLimitePago),
          ]),
          const SizedBox(height: 12),
          _seccion('Montos', [
            _fila('Monto base', _fmt(cobro.montoBase)),
            if (cobro.montoMora > 0)
              _fila('Mora', _fmt(cobro.montoMora), color: Colors.red),
            _fila('Total a pagar', _fmt(cobro.montoTotal), bold: true),
          ]),
        ],
      ),
      bottomNavigationBar: (cobro.esPendiente || cobro.esVencido)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RegistrarPagoScreen(cobro: cobro)),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Registrar Pago'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _estadoBadge(Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Estado: ${cobro.estado}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16)),
            Text(_fmt(cobro.montoTotal),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 20)),
          ],
        ),
      );

  Widget _seccion(String titulo, List<Widget> hijos) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 16),
              child: Column(children: hijos),
            ),
          ),
        ],
      );

  Widget _fila(String label, String valor,
      {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey)),
            Text(valor,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
          ],
        ),
      );

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
