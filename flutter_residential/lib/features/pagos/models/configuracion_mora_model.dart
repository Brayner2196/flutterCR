class ConfiguracionMoraModel {
  final int id;
  final String tipoCalculo; // 'PORCENTAJE' | 'MONTO_FIJO'
  final double? porcentajeMensual;
  final double? montoFijo;
  final int diasGracia;
  final bool activo;
  final String fechaVigencia; // ISO date
  final String? creadoEn;

  const ConfiguracionMoraModel({
    required this.id,
    required this.tipoCalculo,
    this.porcentajeMensual,
    this.montoFijo,
    required this.diasGracia,
    required this.activo,
    required this.fechaVigencia,
    this.creadoEn,
  });

  factory ConfiguracionMoraModel.fromJson(Map<String, dynamic> json) =>
      ConfiguracionMoraModel(
        id: json['id'] as int,
        tipoCalculo: json['tipoCalculo'] as String,
        porcentajeMensual: json['porcentajeMensual'] != null
            ? (json['porcentajeMensual'] as num).toDouble()
            : null,
        montoFijo: json['montoFijo'] != null
            ? (json['montoFijo'] as num).toDouble()
            : null,
        diasGracia: json['diasGracia'] as int? ?? 0,
        activo: json['activo'] as bool,
        fechaVigencia: json['fechaVigencia'] as String,
        creadoEn: json['creadoEn'] as String?,
      );
}
