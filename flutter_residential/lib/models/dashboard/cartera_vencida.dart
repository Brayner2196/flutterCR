class CarteraVencida {
  final double monto;
  final double variacionMonto;
  final int unidadesEnMora;

  const CarteraVencida({
    required this.monto,
    required this.variacionMonto,
    required this.unidadesEnMora,
  });

  factory CarteraVencida.fromJson(Map<String, dynamic> json) => CarteraVencida(
        monto: (json['monto'] as num? ?? 0).toDouble(),
        variacionMonto: (json['variacionMonto'] as num? ?? 0).toDouble(),
        unidadesEnMora: (json['unidadesEnMora'] as num).toInt(),
      );
}
