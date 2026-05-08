class PendientesHoy {
  final int comprobantes;
  final int pqrs;
  final int reservas;
  final int total;

  const PendientesHoy({
    required this.comprobantes,
    required this.pqrs,
    required this.reservas,
    required this.total,
  });

  factory PendientesHoy.fromJson(Map<String, dynamic> json) => PendientesHoy(
        comprobantes: (json['comprobantes'] as num).toInt(),
        pqrs: (json['pqrs'] as num).toInt(),
        reservas: (json['reservas'] as num).toInt(),
        total: (json['total'] as num).toInt(),
      );

  static const empty = PendientesHoy(comprobantes: 0, pqrs: 0, reservas: 0, total: 0);
}
