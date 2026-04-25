class ConfiguracionCuotaModel {
  final int id;
  final int? tipoPropiedadId;
  final int? propiedadId;
  final double monto;
  final String periodicidad;
  final String fechaVigenciaDesde;
  final bool activo;

  const ConfiguracionCuotaModel({
    required this.id,
    this.tipoPropiedadId,
    this.propiedadId,
    required this.monto,
    required this.periodicidad,
    required this.fechaVigenciaDesde,
    required this.activo,
  });

  factory ConfiguracionCuotaModel.fromJson(Map<String, dynamic> json) =>
      ConfiguracionCuotaModel(
        id: json['id'] as int,
        tipoPropiedadId: json['tipoPropiedadId'] as int?,
        propiedadId: json['propiedadId'] as int?,
        monto: (json['monto'] as num).toDouble(),
        periodicidad: json['periodicidad'] as String,
        fechaVigenciaDesde: json['fechaVigenciaDesde'] as String,
        activo: json['activo'] as bool,
      );

  Map<String, dynamic> toJson() => {
        if (tipoPropiedadId != null) 'tipoPropiedadId': tipoPropiedadId,
        if (propiedadId != null) 'propiedadId': propiedadId,
        'monto': monto,
        'periodicidad': periodicidad,
        'fechaVigenciaDesde': fechaVigenciaDesde,
      };
}
