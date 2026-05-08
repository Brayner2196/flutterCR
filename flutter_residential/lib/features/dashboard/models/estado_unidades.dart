class EstadoUnidades {
  final int total;
  final int alDia;
  final int porVencer;
  final int enMora;

  const EstadoUnidades({
    required this.total,
    required this.alDia,
    required this.porVencer,
    required this.enMora,
  });

  factory EstadoUnidades.fromJson(Map<String, dynamic> json) => EstadoUnidades(
        total: (json['total'] as num).toInt(),
        alDia: (json['alDia'] as num).toInt(),
        porVencer: (json['porVencer'] as num).toInt(),
        enMora: (json['enMora'] as num).toInt(),
      );
}
