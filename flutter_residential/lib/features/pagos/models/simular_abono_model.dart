import 'movimiento_abono_model.dart';

class SimularAbonoModel {
  final double montoAbono;
  final double saldoFavorPrevio;
  final double totalDisponible;
  final List<MovimientoAbonoModel> distribucion;
  final double saldoFavorResultante;

  const SimularAbonoModel({
    required this.montoAbono,
    required this.saldoFavorPrevio,
    required this.totalDisponible,
    required this.distribucion,
    required this.saldoFavorResultante,
  });

  factory SimularAbonoModel.fromJson(Map<String, dynamic> json) =>
      SimularAbonoModel(
        montoAbono: (json['montoAbono'] as num).toDouble(),
        saldoFavorPrevio: (json['saldoFavorPrevio'] as num? ?? 0).toDouble(),
        totalDisponible: (json['totalDisponible'] as num).toDouble(),
        distribucion: (json['distribucion'] as List? ?? [])
            .map((e) => MovimientoAbonoModel.fromJson(e))
            .toList(),
        saldoFavorResultante:
            (json['saldoFavorResultante'] as num? ?? 0).toDouble(),
      );
}
