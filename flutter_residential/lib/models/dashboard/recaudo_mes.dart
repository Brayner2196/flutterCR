class RecaudoMes {
  final int anio;
  final int mes;
  final int porcentaje;
  final int puntosVariacion;
  final double recaudado;
  final double esperado;

  /// Monto recaudado proveniente de cobros de periodos anteriores (cobros viejos).
  final double recaudadoCobrosViejos;

  const RecaudoMes({
    required this.anio,
    required this.mes,
    required this.porcentaje,
    required this.puntosVariacion,
    required this.recaudado,
    required this.esperado,
    this.recaudadoCobrosViejos = 0,
  });

  factory RecaudoMes.fromJson(Map<String, dynamic> json) => RecaudoMes(
        anio: (json['anio'] as num).toInt(),
        mes: (json['mes'] as num).toInt(),
        porcentaje: (json['porcentaje'] as num).toInt(),
        puntosVariacion: (json['puntosVariacion'] as num).toInt(),
        recaudado: (json['recaudado'] as num? ?? 0).toDouble(),
        esperado: (json['esperado'] as num? ?? 0).toDouble(),
        recaudadoCobrosViejos:
            (json['recaudadoCobrosViejos'] as num? ?? 0).toDouble(),
      );
}
