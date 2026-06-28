class ValidarVisitaModel {
  final bool permitido;
  final String? estado;
  final String? nombreVisitante;
  final String? documento;
  final String? placa;
  final int? propiedadId;
  final String? propiedadIdentificador;
  final String? mensaje;

  const ValidarVisitaModel({
    required this.permitido,
    this.estado,
    this.nombreVisitante,
    this.documento,
    this.placa,
    this.propiedadId,
    this.propiedadIdentificador,
    this.mensaje,
  });

  factory ValidarVisitaModel.fromJson(Map<String, dynamic> json) =>
      ValidarVisitaModel(
        permitido: json['permitido'] as bool? ?? false,
        estado: json['estado'] as String?,
        nombreVisitante: json['nombreVisitante'] as String?,
        documento: json['documento'] as String?,
        placa: json['placa'] as String?,
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        propiedadIdentificador: json['propiedadIdentificador'] as String?,
        mensaje: json['mensaje'] as String?,
      );
}
