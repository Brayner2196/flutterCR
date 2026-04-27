class TendenciaMes {
  final int anio;
  final int mes;
  final String etiqueta;
  final int porcentaje;

  const TendenciaMes({
    required this.anio,
    required this.mes,
    required this.etiqueta,
    required this.porcentaje,
  });

  factory TendenciaMes.fromJson(Map<String, dynamic> json) => TendenciaMes(
        anio: (json['anio'] as num).toInt(),
        mes: (json['mes'] as num).toInt(),
        etiqueta: json['etiqueta'] as String,
        porcentaje: (json['porcentaje'] as num).toInt(),
      );
}

class Tendencia {
  final List<TendenciaMes> meses;
  final String tendencia;

  const Tendencia({required this.meses, required this.tendencia});

  factory Tendencia.fromJson(Map<String, dynamic> json) => Tendencia(
        meses: (json['meses'] as List)
            .map((e) => TendenciaMes.fromJson(e as Map<String, dynamic>))
            .toList(),
        tendencia: json['tendencia'] as String? ?? 'ESTABLE',
      );

  bool get esMejorando => tendencia == 'MEJORANDO';
  bool get esEmpeorando => tendencia == 'EMPEORANDO';
}
