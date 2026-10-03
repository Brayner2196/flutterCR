import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/format_moneda.dart';
import '../models/simulacion_acuerdo_model.dart';

/// Cuotas diferidas como "Cuota N · fecha ........ valor".
///
/// La comparten la previsualización del residente, la tarjeta de su solicitud
/// y el detalle del admin, para que el cronograma se lea igual en todas.
/// Solo pinta: los montos y las fechas vienen calculados del backend.
class CronogramaCuotas extends StatelessWidget {
  final List<CuotaSimuladaModel> cuotas;

  const CronogramaCuotas({super.key, required this.cuotas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final c in cuotas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuota ${c.numero}  ·  ${DateFormatter.fecha(c.fechaVencimiento)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                Text(
                  FormatMoneda.format(c.monto),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
