class MovimientoAbonoModel {
  final int? cobroId;
  final double montoAplicado;
  final String descripcion;

  const MovimientoAbonoModel({
    this.cobroId,
    required this.montoAplicado,
    required this.descripcion,
  });

  factory MovimientoAbonoModel.fromJson(Map<String, dynamic> json) =>
      MovimientoAbonoModel(
        cobroId: json['cobroId'] as int?,
        montoAplicado: (json['montoAplicado'] as num).toDouble(),
        descripcion: json['descripcion'] as String? ?? '',
      );

  bool get esSaldoFavor => cobroId == null;
}
