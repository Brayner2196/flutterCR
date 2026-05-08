class SaldoFavorModel {
  final int propiedadId;
  final double saldo;

  const SaldoFavorModel({required this.propiedadId, required this.saldo});

  factory SaldoFavorModel.fromJson(Map<String, dynamic> json) => SaldoFavorModel(
        propiedadId: json['propiedadId'] as int,
        saldo: (json['saldo'] as num? ?? 0).toDouble(),
      );

  bool get tieneSaldo => saldo > 0;
}
