import 'package:flutter/material.dart';
import '../../../shared/widgets/metrica_card.dart';
import '../utils/urgencia_cobranza_ui.dart';

/// Cuadrícula 2x2 de la cobranza: vencidos, por vencer, con mora y críticos.
/// Cada tarjeta filtra la lista; al volver a tocarla, quita el filtro.
///
/// No reutiliza `EstadoResumenGrid` porque aquí no se cuentan estados de cobro
/// (en cobranza no existen ni PAGADO ni EXONERADO): se cuenta urgencia, que es
/// lo que decide a quién se llama primero.
class CobranzaMetricasGrid extends StatelessWidget {
  /// Conteos por clave: POR_VENCER, VENCIDO, MORA, CRITICO.
  final Map<String, int> counts;
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  /// Días a partir de los cuales un vencido es crítico (para la etiqueta).
  final int diasCritico;

  const CobranzaMetricasGrid({
    super.key,
    required this.counts,
    required this.seleccionado,
    required this.onSeleccionar,
    this.diasCritico = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          Row(children: [
            _celda(UrgenciaCobranzaUi.vencido, alerta: true),
            const SizedBox(width: 10),
            _celda(UrgenciaCobranzaUi.porVencer),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _celda(UrgenciaCobranzaUi.mora),
            const SizedBox(width: 10),
            _celda(UrgenciaCobranzaUi.critico,
                etiqueta: '+$diasCritico días', alerta: true),
          ]),
        ],
      ),
    );
  }

  Widget _celda(UrgenciaCobranzaUi ui, {String? etiqueta, bool alerta = false}) {
    final count = counts[ui.clave] ?? 0;
    return Expanded(
      child: MetricaCard(
        valor: count,
        etiqueta: etiqueta ?? ui.plural,
        icono: ui.icono,
        color: ui.color,
        seleccionado: seleccionado == ui.clave,
        alerta: alerta && count > 0,
        onTap: () => onSeleccionar(ui.clave),
      ),
    );
  }
}
